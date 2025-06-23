# EKS クラスタ用セキュリティグループ
resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.cluster_name}-cluster-sg"
    Environment = var.env
    Terraform   = "true"
  }
}

# EKS ノード用セキュリティグループ
resource "aws_security_group" "node" {
  name        = "${local.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.cluster_name}-node-sg"
    Environment = var.env
    Terraform   = "true"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}

# クラスタとノード間の通信を許可
resource "aws_security_group_rule" "cluster_to_node" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  description              = "Allow nodes to communicate with the cluster API Server"
}

resource "aws_security_group_rule" "node_to_cluster" {
  security_group_id        = aws_security_group.node.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  description              = "Allow cluster control plane to communicate with worker nodes"
}

# 踏み台サーバーからのアクセスを許可
resource "aws_security_group_rule" "cluster_ingress_bastion" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  description              = "Allow bastion to communicate with the cluster API Server"
}

# ノード間の通信を許可
resource "aws_security_group_rule" "node_to_node" {
  security_group_id        = aws_security_group.node.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  description              = "Allow worker nodes to communicate with each other"
}

# EKSノードからDocumentDBへのアクセスを許可
resource "aws_security_group_rule" "eks_to_documentdb" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = var.documentdb_security_group_id
  description              = "Allow MongoDB connection from EKS nodes"
}