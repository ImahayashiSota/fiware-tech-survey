# データソース: 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# データソース: 現在のAWSリージョン情報
data "aws_region" "current" {}

# Lambda実行用IAMロール
resource "aws_iam_role" "lambda_role" {
  name = "${var.env}-${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.lambda_function_name}-role"
    Environment = var.env
  })
}

# Lambda基本実行ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# リソース管理用のカスタムポリシー
resource "aws_iam_policy" "lambda_resource_policy" {
  name        = "${var.env}-${var.lambda_function_name}-resource-policy"
  description = "Policy for resource scheduler Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "docdb:DescribeDBClusters",
          "docdb:StartDBCluster",
          "docdb:StopDBCluster",
          "docdb:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.env}-${var.lambda_function_name}:*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.lambda_function_name}-resource-policy"
    Environment = var.env
  })
}

# DynamoDB用のポリシー（有効化されている場合のみ）
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  count = var.enable_nodegroup_config_table ? 1 : 0

  name        = "${var.env}-${var.lambda_function_name}-dynamodb-policy"
  description = "Policy for DynamoDB access from resource scheduler Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.nodegroup_configs[0].arn
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.lambda_function_name}-dynamodb-policy"
    Environment = var.env
  })
}

# カスタムポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "lambda_resource_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_resource_policy.arn
}

# DynamoDBポリシーをロールにアタッチ（有効化されている場合のみ）
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  count = var.enable_nodegroup_config_table ? 1 : 0

  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy[0].arn
}

# CloudWatch Logs グループ
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.env}-${var.lambda_function_name}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.lambda_function_name}-logs"
    Environment = var.env
  })
}

# Lambda関数用のZIPファイルを作成
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# Lambda関数
resource "aws_lambda_function" "scheduler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.env}-${var.lambda_function_name}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda.lambda_handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SCHEDULE_TAG_KEY   = var.schedule_tag_key
      SCHEDULE_TAG_VALUE = var.schedule_tag_value
      NODEGROUP_CONFIG_TABLE = var.enable_nodegroup_config_table ? aws_dynamodb_table.nodegroup_configs[0].name : ""
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_resource_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.lambda_function_name}"
    Environment = var.env
  })
}

# EventBridge ルール: 平日20:00に停止
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "${var.env}-resource-stop-schedule"
  description         = "Trigger resource stop at 20:00 JST on weekdays"
  schedule_expression = var.stop_schedule

  tags = merge(var.tags, {
    Name        = "${var.env}-resource-stop-schedule"
    Environment = var.env
  })
}

# EventBridge ルール: 平日08:00に開始
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "${var.env}-resource-start-schedule"
  description         = "Trigger resource start at 08:00 JST on weekdays"
  schedule_expression = var.start_schedule

  tags = merge(var.tags, {
    Name        = "${var.env}-resource-start-schedule"
    Environment = var.env
  })
}

# EventBridge ルール: 土日00:00に停止
resource "aws_cloudwatch_event_rule" "weekend_stop_schedule" {
  name                = "${var.env}-resource-weekend-stop-schedule"
  description         = "Trigger resource stop at 00:00 JST on weekends"
  schedule_expression = var.weekend_stop_schedule

  tags = merge(var.tags, {
    Name        = "${var.env}-resource-weekend-stop-schedule"
    Environment = var.env
  })
}

# EventBridge ターゲット: 停止スケジュール
resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "StopResourceTarget"
  arn       = aws_lambda_function.scheduler.arn

  input = jsonencode({
    action = "stop"
  })
}

# EventBridge ターゲット: 開始スケジュール
resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "StartResourceTarget"
  arn       = aws_lambda_function.scheduler.arn

  input = jsonencode({
    action = "start"
  })
}

# EventBridge ターゲット: 週末停止スケジュール
resource "aws_cloudwatch_event_target" "weekend_stop_target" {
  rule      = aws_cloudwatch_event_rule.weekend_stop_schedule.name
  target_id = "WeekendStopResourceTarget"
  arn       = aws_lambda_function.scheduler.arn

  input = jsonencode({
    action = "stop"
  })
}

# Lambda実行権限: 停止スケジュール
resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}

# Lambda実行権限: 開始スケジュール
resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}

# Lambda実行権限: 週末停止スケジュール
resource "aws_lambda_permission" "allow_eventbridge_weekend_stop" {
  statement_id  = "AllowExecutionFromEventBridgeWeekendStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekend_stop_schedule.arn
}

# DynamoDB テーブル: EKSノードグループ設定保存用（オプション）
resource "aws_dynamodb_table" "nodegroup_configs" {
  count = var.enable_nodegroup_config_table ? 1 : 0

  name           = "${var.env}-${var.nodegroup_config_table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "cluster_nodegroup"

  attribute {
    name = "cluster_nodegroup"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(var.tags, {
    Name        = "${var.env}-${var.nodegroup_config_table_name}"
    Environment = var.env
  })
}