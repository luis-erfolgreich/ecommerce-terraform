# ==============================
# IAM Role da Lambda
# ==============================

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ==============================
# Permissões da Lambda
# ==============================

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = aws_sqs_queue.pedidos.arn
      },
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ==============================
# Código da Lambda
# ==============================

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/app/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# ==============================
# Função Lambda
# ==============================

resource "aws_lambda_function" "pedidos" {
  function_name = "${var.project_name}-lambda"
  role          = aws_iam_role.lambda_exec.arn

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout = 30

  depends_on = [
    aws_iam_role_policy.lambda_policy
  ]
}

# ==============================
# CloudWatch Logs
# ==============================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.pedidos.function_name}"
  retention_in_days = 7
}

# ==============================
# Trigger SQS → Lambda
# ==============================

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.pedidos.arn
  function_name    = aws_lambda_function.pedidos.arn

  batch_size = 1
  enabled    = true
}
