# ami
data "aws_ami" "base_ami" {
  most_recent = true  # 最新のAMIを取得
  owners = ["amazon"]  # AmazonのAMIを所有者として指定

  filter {
    name   = "name"
    values = [var.aws_ec2.ami_name_filter]  # 変数からAMI名のフィルターを取得
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]  # EBSをルートデバイスタイプとして指定
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # HVM仮想化タイプを指定
  }
}
