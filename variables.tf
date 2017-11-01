variable "aws_region" {}
variable "environment" {}
variable "instance_type" {}
variable "key_name" {}
variable "key" {}
variable "pem_key" {}
variable "private_key" {}

variable "product" {
  default = "elk"
}

variable "spot_price" {}
variable "stack_name" {}
