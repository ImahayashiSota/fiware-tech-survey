variable "env" {
  type = string
  description = "環境名"
}

variable "region" {
  type = string
  description = "AWSリージョン"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type = list(string)
  description = "DocumentDBクラスターを配置するサブネットIDのリスト"
}

variable "bastion_sg_id" {
  type = string
  description = "BastionホストのセキュリティグループID"
}

variable "instance_class" {
  type = string
  description = "DocumentDBインスタンスクラス"
  default = "db.t3.medium"
}

variable "master_username" {
  type = string
  description = "DocumentDBのマスターユーザー名"
  default = "docdbadmin"
}

variable "master_password" {
  type = string
  description = "DocumentDBのマスターパスワード"
  sensitive = true
}

variable "engine_version" {
  type = string
  description = "DocumentDBのエンジンバージョン"
  default = "4.0.0"
}

variable "instance_count" {
  type = number
  description = "DocumentDBインスタンスの数"
  default = 1
}