variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_a" {
  type        = string
  description = "CIDR block for public subnet a"
}

variable "public_subnet_d" {
  type        = string
  description = "CIDR block for public subnet d"
}

variable "private_subnet_a" {
  type        = string
  description = "CIDR block for private subnet a"
}

variable "private_subnet_d" {
  type        = string
  description = "CIDR block for private subnet d"
}