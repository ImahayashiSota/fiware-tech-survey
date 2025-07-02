# Dockerコマンドのインストールが、user_dataで実行されないため、手動で起動
# #!/bin/bash

# # Dockerのインストール
# sudo dnf install -y docker
# sudo systemctl start docker
# sudo systemctl enable docker

# # ユーザーをdockerグループに追加（EC2-Userの場合）
# usermod -a -G docker ec2-user

# # 一度ログアウトして再ログインする必要があります

# # CrateDBコンテナの起動
# docker run -d \
#   --name cratedb \
#   --restart=always \
#   -p 4200:4200 \
#   -p 5432:5432 \
#   crate/crate:latest
