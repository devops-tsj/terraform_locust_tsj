variable "region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS Region."
}

variable "switch_role_arn" {
  type        = string
  description = "Costumer Switch Role ARN."
}

variable "prefix_name" {
  type = string
}

variable "env" {
  type = string
}

variable "keypair" {
  type        = any
  default     = {}
  description = "keypair configuration block."
}

variable "instance" {
  type        = any
  default     = {}
  description = "instance configuration block."
}

variable "openvpn" {
  type        = any
  default     = {}
  description = "openvpn configuration block."
}

variable "vpc" {
  type        = any
  default     = {}
  description = "vpc configuration block."
}