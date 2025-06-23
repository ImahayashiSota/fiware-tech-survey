# SSHキー
# TODO: ログやtfstateに中身が残るので別途管理が望ましい →　32行目
# resource "tls_private_key" "ssh_key" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# ローカルに秘密鍵を作成
# resource "local_file" "private_key_pem" {
#  filename = "./ssh_keys/id_rsa"
#  content_base64 = base64encode(tls_private_key.ssh_key.private_key_pem)
#  depends_on = [tls_private_key.ssh_key]
#  provisioner "local-exec" {
#    command = "chmod 600 ./ssh_keys/id_rsa"
#  }
#}

# ローカルに公開鍵を作成
#resource "local_file" "public_key_openssh" {
#  filename = "./ssh_keys/id_rsa.pub"
#  content_base64 = base64encode(tls_private_key.ssh_key.public_key_openssh)
#  depends_on = [tls_private_key.ssh_key]
#  provisioner "local-exec" {
#    command = "chmod 600 ./ssh_keys/id_rsa.pub"
#  }
#}

# AWS リソースとして登録する
resource "aws_key_pair" "ssh_key" {
  key_name = "${var.env}-ssh-key"
#  public_key = tls_private_key.ssh_key.public_key_openssh
  public_key = file("../../../ssh_keys/id_rsa.pub") # ローカルに保存した公開鍵を使用
#  depends_on = [tls_private_key.ssh_key]
}
