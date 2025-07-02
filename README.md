# fiware-tech-survey
FIWAREを用いたスマートシティ向け都市OSの構築に関する技術調査リポジトリです。

## 概要
このプロジェクトは、FIWAREプラットフォームを利用したスマートシティ向け都市OS（City OS）の構築・検証を目的としています。AWS環境上でFIWAREコンポーネントを展開し、都市データの収集・管理・分析基盤を提供します。

## プロジェクト構成

### インフラストラクチャ
- **terraform/** - AWS環境のIaC（Infrastructure as Code）
  - **environments/** - 環境別設定（city1, city2）
  - **modules/** - 再利用可能なTerraformモジュール
    - vpc/ - VPC/ネットワーキング設定
    - eks/ - EKSクラスター設定
    - ec2/ - EC2インスタンス設定（Bastion、CrateDB）
    - documentdb/ - DocumentDB設定

### Kubernetesマニフェスト
- **k8s/** - Kubernetes上でのFIWAREコンポーネント展開設定
  - **orion/** - Orion Context Broker設定
  - **quantumleap/** - QuantumLeap時系列データ管理設定

### 動作確認・テスト
- **curl/** - APIテスト用cURLコマンド集
  - orion - Orion Context Broker API テスト
  - cratedb - CrateDB接続・クエリテスト
  - quantumleap - QuantumLeap API テスト

### ユーティリティ
- **aws/** - AWS関連スクリプト・設定
- **ssh_keys/** - SSH接続用キーファイル
- **subscription_analyzer.sh** - サブスクリプション分析スクリプト

## 主要技術スタック
- **FIWARE**: Context管理・時系列データ処理
  - Orion Context Broker
  - QuantumLeap
- **AWS**: クラウドインフラ
  - EKS (Kubernetes)
  - EC2, VPC, DocumentDB
- **CrateDB**: 時系列データストレージ
- **Terraform**: インフラ自動化
- **Kubernetes**: コンテナオーケストレーション

## セットアップ・利用方法

### 1. AWS環境構築
```bash
cd terraform/environments/city1
terraform init
terraform plan
terraform apply
```

### 2. FIWAREコンポーネントデプロイ
```bash
kubectl apply -f k8s/orion/
kubectl apply -f k8s/quantumleap/
```

## 関連資料
- memo.txt: 開発メモ・注意事項
