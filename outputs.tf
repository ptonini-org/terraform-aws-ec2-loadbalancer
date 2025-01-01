output "this" {
  value = aws_lb.this
}

output "listener_arns" {
  value = {for k, v in module.listeners : k => v.this.arn}
}

output "api_gateway_vpc_link" {
  value = var.create_api_gateway_vpc_link ? aws_api_gateway_vpc_link.this : null
}