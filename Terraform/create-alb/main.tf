# # Required provideres block
# terraform {
#     required_providers {
#         aws = {
#             source = "hashicorp/aws"
#             version = "~> 3.0"
#         }
#     }  
# }

# Variables block
variable "vpc_id" {}

variable "app_name" {}

variable "app_port" {}

variable "source_cidr" {}

variable "aws_region" {}

# For Local Tests Only


# variable "aws_creds" {
#   type = object({
#       access_key = string
#       secret_key = string
#   })
#   sensitive = true
# }

# Providers block
provider "aws" {
    region = var.aws_region
    # access_key = var.aws_creds.access_key
    # secret_key = var.aws_creds.secret_key
}

# Data Block
data "aws_vpc" "selected_vpc" {
    id = var.vpc_id
}

data "aws_subnets" "app-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["app-subnet-*"]
  }
}

data "aws_instance" "app_instance" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.app_name}*"]
  }
}

# Resources block
resource "aws_security_group" "alb_sg" {
  name              = "ALB SG from TF"
  description       = "Security group for ALB created from Terraform"
  vpc_id            = var.vpc_id

  ingress = [
    {
      description      = "HTTP"
      from_port        = var.app_port
      to_port          = var.app_port
      protocol         = "tcp"
      cidr_blocks      = [var.source_cidr]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  egress = [
    {
      description      = "All Traffic"      
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]
}

# Add a security group rule to the existing instance security group in order to allow traffic to the instance from the LB
resource "aws_security_group_rule" "Allow_traffic_from_ALB_To_instance_rule" {
  type              = "ingress"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  cidr_blocks       = null
  ipv6_cidr_blocks  = null
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id = tolist(data.aws_instance.app_instance.vpc_security_group_ids)[0]
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "torque-${var.app_name}-alb-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/wp-includes/images/blank.gif"
    port = var.app_port
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200-299"  # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "alb_target_group_instance_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = data.aws_instance.app_instance.id
  port             = var.app_port
}

resource "aws_lb" "app_lb" {
  name                = "torque-${var.app_name}-alb"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.alb_sg.id]
  subnets             = data.aws_subnets.app-subnets.ids 
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = var.app_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# Outputs block
output app_url {
  value       = "${aws_lb.app_lb.dns_name}:${var.app_port}"
  sensitive   = false
  description = "App URL"
  depends_on  = []
}
