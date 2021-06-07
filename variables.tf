# Required
variable "aws_access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
}

# Required
variable "aws_secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS availability zone used for all resources"
  default     = "us-east-1a"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "test"
}

variable "instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "t3a.medium"
}

# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
}
