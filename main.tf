data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current" {}

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  subnets            = var.subnet_ids
  security_groups    = concat(module.security_group[*].this.id, var.additional_security_groups)
  load_balancer_type = var.load_balancer_type

  dynamic "access_logs" {
    for_each = var.access_logs[*]
    content {
      enabled = access_logs.value.enabled
      bucket  = coalesce(access_logs.value.bucket, module.log_bucket[0].this.id)
    }
  }

  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["product"],
      tags["env"],
      tags_all
    ]
  }
}

resource "aws_api_gateway_vpc_link" "this" {
  count       = var.create_api_gateway_vpc_link ? 1 : 0
  name        = var.name
  target_arns = [aws_lb.this.arn]
}

module "log_bucket" {
  source        = "app.terraform.io/ptonini-org/s3-bucket/aws"
  version       = "~> 1.0.0"
  count         = var.log_bucket == null ? 0 : 1
  name          = var.log_bucket.name
  create_policy = false
  force_destroy = var.log_bucket.force_destroy
  bucket_policy_statements = [
    {
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "arn:aws:s3:::${var.log_bucket.name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "arn:aws:s3:::${var.log_bucket.name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = "s3:GetBucketAcl"
      Resource  = "arn:aws:s3:::${var.log_bucket.name}"
    }
  ]
}

module "security_group" {
  source        = "app.terraform.io/ptonini-org/security-group/aws"
  version       = "~> 1.0.0"
  count         = var.security_group == null ? 0 : 1
  name          = "lb-${var.name}"
  vpc_id        = var.security_group.vpc_id
  ingress_rules = var.security_group.ingress_rules
  egress_rules  = var.security_group.egress_rules
}

module "listeners" {
  source          = "app.terraform.io/ptonini-org/ec2-loadbalancer-listener/aws"
  version         = "~> 1.0.0"
  for_each        = var.listeners
  load_balancer   = aws_lb.this
  port            = each.value.port
  protocol        = each.value.protocol
  certificate     = each.value.certificate
  default_actions = each.value.default_actions
  rules           = each.value.rules
}