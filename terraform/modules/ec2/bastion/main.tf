resource "aws_security_group" "bastion" {
  vpc_id = var.vpc_id  # 最初のVPCを使う
  name   = "${var.env}-bastion"

  ingress {
    description = "SSH from my global IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "24.239.154.22/32",
      "24.239.154.23/32",
      "24.239.132.16/32",
      "24.239.132.17/32",
      "24.239.141.18/32",
      "24.239.141.19/32",
      "24.239.147.26/32",
      "24.239.147.27/32"
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 全てのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"] # 全てのIPアドレスへのアウトバウンドトラフィックを許可
  }
  
  tags = {
    Environment = "${var.env}"
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "${var.env}-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole"]  # 配列形式で記述
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.env}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role_policy" "bastion_eks_policy" {
  name = "${var.env}-bastion-eks-policy"
  role = aws_iam_role.bastion_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# または管理ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.bastion_role.name
}

# EC2 踏み台
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.base_ami.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name      = "${var.env}-ssh-key"
  vpc_security_group_ids = [aws_security_group.bastion.id] 
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
  root_block_device {
    volume_type           = var.aws_ec2.volume_type
    volume_size           = var.aws_ec2.volume_size
  }
  tags = {
    Name = "${var.env}-bastion"
    Environment = "${var.env}"
    Schedule = "true"
  }
  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

resource "aws_eip" "bastion_eip" {
  domain   = "vpc"
  instance = aws_instance.bastion.id
}
