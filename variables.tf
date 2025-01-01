variable "name" {
  default = null
}

variable "internal" {
  default  = false
  nullable = false
}

variable "load_balancer_type" {
  default  = "application"
  nullable = false
}

variable "subnet_ids" {
  type = list(string)
}

variable "access_logs" {
  type = object({
    enabled = optional(bool, true)
    bucket  = optional(string)
  })
  default  = {}
  nullable = false
}

variable "log_bucket" {
  type = object({
    name          = string
    force_destroy = optional(bool, true)
  })
  default = null
}

variable "security_group" {
  type = object({
    vpc_id = string
    ingress_rules = optional(map(object({
      from_port                    = optional(number)
      to_port                      = optional(number)
      ip_protocol                  = optional(string, "tcp")
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
    })), { self = { ip_protocol = -1, referenced_security_group_id = "self" } })
    egress_rules = optional(map(object({
      from_port                    = optional(number)
      to_port                      = optional(number)
      ip_protocol                  = optional(string, "tcp")
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
    })), { all = { ip_protocol = -1, cidr_ipv4 = "0.0.0.0/0" } })
  })
  default = null
}

variable "additional_security_groups" {
  type     = list(string)
  default  = []
  nullable = false
}

variable "listeners" {
  type = map(object({
    port     = optional(number)
    protocol = optional(string)
    certificate = optional(object({
      arn = optional(string)
    }))
    default_actions = optional(map(any))
    rules = optional(map(object({
      type             = string
      target_group_arn = optional(string)
      redirects = optional(object({
        host        = optional(string)
        path        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        query       = optional(string)
        status_code = optional(string, "HTTP_301")
      }))
      conditions = map(object({
        host_header         = optional(set(string))
        path_pattern        = optional(set(string))
        http_request_method = optional(set(string))
        source_ip           = optional(set(string))
        http_header         = optional(map(string), {})
        query_string        = optional(map(string), {})
      }))
    })))
  }))
  default  = {}
  nullable = false
}

variable "create_api_gateway_vpc_link" {
  default  = false
  nullable = false
}