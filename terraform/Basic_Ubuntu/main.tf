# require provideres block
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>2.0"
            
        }
    }  
}

# variable "aws_creds" {
#   type = object({
#       access_key = string
#       secret_key = string
#   })
#   sensitive = true
# }

variable "region" {}

# Provider block
provider "aws" {
    region = var.region
    # access_key = var.aws_creds.access_key
    # secret_key = var.aws_creds.secret_key
}

# Resources block
resource "aws_instance" "TF_Exmaple_ubuntu" {
    ami = "ami-07dd19a7900a1f049"
    instance_type = "t3a.nano"
    key_name = "CloudshellKP"
    tags = {
      "Name" = "TF_Example - Ubuntu"
    }

}