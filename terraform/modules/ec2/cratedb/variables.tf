variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "aws_ec2" {
  description = "EC2 instance settings"
  type = object({
    ami_name_filter        = string
    volume_type            = string
    volume_size            = number
    delete_on_termination  = bool
  })
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
} 

variable "key_name" {
  description = "SSH key pair name for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  type        = string
}

variable "eks_node_sg_id" {
  description = "EKSノードのセキュリティグループID"
  type        = string
}
