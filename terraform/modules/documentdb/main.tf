# DocumentDB用セキュリティグループ
resource "aws_security_group" "documentdb" {
  name        = "${var.env}-documentdb-sg"
  description = "Security group for DocumentDB"
  vpc_id      = var.vpc_id

  # Bastionからの接続のみを許可
  ingress {
    description     = "Allow MongoDB connection from bastion"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-documentdb-sg"
    Environment = var.env
  }
}

# DocumentDBサブネットグループ
resource "aws_docdb_subnet_group" "documentdb" {
  name       = "${var.env}-documentdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.env}-documentdb-subnet-group"
    Environment = var.env
  }
}

# DocumentDBクラスターパラメータグループ
resource "aws_docdb_cluster_parameter_group" "documentdb" {
  family      = "docdb4.0"
  name        = "${var.env}-documentdb-cluster-params"
  description = "DocumentDB cluster parameter group"

  parameter {
    name  = "tls"
    value = "disabled"  # SSLを無効化（セキュリティ上の理由から本番環境では推奨しません）
  }

  tags = {
    Name        = "${var.env}-documentdb-cluster-params"
    Environment = var.env
  }
}

# DocumentDBクラスター
resource "aws_docdb_cluster" "documentdb" {
  cluster_identifier              = "${var.env}-documentdb-cluster"
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_docdb_subnet_group.documentdb.name
  vpc_security_group_ids          = [aws_security_group.documentdb.id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.documentdb.name
  skip_final_snapshot             = true
  deletion_protection             = false

  tags = {
    Name        = "${var.env}-documentdb-cluster"
    Environment = var.env
    Schedule    = "true"
  }
}

# DocumentDBインスタンス
resource "aws_docdb_cluster_instance" "documentdb_instances" {
  count              = var.instance_count
  identifier         = "${var.env}-documentdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.documentdb.id
  instance_class     = var.instance_class

  tags = {
    Name        = "${var.env}-documentdb-instance-${count.index}"
    Environment = var.env
  }
}
