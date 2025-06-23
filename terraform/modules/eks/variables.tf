variable "env" {
  description = "環境名（例：city1）"
  type        = string
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_id" {
  description = "既存のVPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "プライベートサブネットのIDリスト"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKSクラスタ名"
  type        = string
  default     = null # nullの場合は"${var.env}-eks-cluster"が使用される
}

variable "kubernetes_version" {
  description = "Kubernetesバージョン"
  type        = string
  default     = "1.32"
}

variable "node_instance_type" {
  description = "ノードグループのインスタンスタイプ"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "ノードグループの希望ノード数"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "ノードグループの最小ノード数"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "ノードグループの最大ノード数"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "ノードのディスクサイズ（GB）"
  type        = number
  default     = 40
}

variable "bastion_security_group_id" {
  description = "踏み台サーバーのセキュリティグループID"
  type        = string
}

variable "map_roles" {
  description = "EKSへのアクセスを許可するIAMロールのリスト"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "EKSへのアクセスを許可するIAMユーザーのリスト"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "bastion_role_arn" {
  description = "IAM role ARN for bastion host access to EKS"
  type        = string
  default     = ""
}

variable "documentdb_security_group_id" {
  description = "DocumentDBのセキュリティグループID"
  type        = string
  default     = ""
}