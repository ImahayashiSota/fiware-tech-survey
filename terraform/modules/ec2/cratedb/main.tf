resource "aws_security_group" "cratedb" {
  vpc_id = var.vpc_id
  name   = "${var.env}-cratedb"

  ingress {
    description     = "Allow SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }
    # CrateDB Web UI用のポート - セキュリティグループルールはルートモジュールで定義
  # EKSノードからの4200ポートへのアクセスは別途定義
  
  # PostgreSQL互換プロトコル用のポート - セキュリティグループルールはルートモジュールで定義
  # EKSノードからの5432ポートへのアクセスは別途定義
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.env}"
  }
}

resource "aws_security_group_rule" "allow_bastion_to_cratedb" {
  type                     = "ingress"
  from_port                = 4200
  to_port                  = 4200
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cratedb.id
  source_security_group_id = var.bastion_sg_id
}


# CrateDB用EC2
resource "aws_instance" "cratedb" {
  ami           = data.aws_ami.base_ami.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name      = "${var.env}-ssh-key"
  vpc_security_group_ids = [aws_security_group.cratedb.id]
  user_data = file("${path.module}/user_data.sh")
  root_block_device {
    volume_type = var.aws_ec2.volume_type
    volume_size = var.aws_ec2.volume_size
  }
  tags = {
    Name        = "${var.env}-cratedb"
    Environment = "${var.env}"
    Schedule    = "true"
  }
  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}
