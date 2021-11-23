variable "my_name" {
    default = "John Doe"
}

output message {
  value       = "Hello World! my name is ${var.my_name}"
  sensitive   = false
  description = "My Message"
  depends_on  = []
}

output url {
  value       = "http://www.google.com"
  sensitive   = false
  description = "App URL"
  depends_on  = []
}