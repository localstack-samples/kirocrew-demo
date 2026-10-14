variable "localstack_endpoint" {
  type        = string
  description = "LocalStack edge endpoint."
  default     = "http://localhost:4566"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb = var.localstack_endpoint
    iam      = var.localstack_endpoint
    lambda   = var.localstack_endpoint
    s3       = var.localstack_endpoint
    sts      = var.localstack_endpoint
  }
}

locals {
  input_bucket = "localstack-ops-input"
  runs_table   = "localstack-ops-runs"
}

resource "aws_s3_bucket" "input" {
  bucket = local.input_bucket
}

resource "aws_dynamodb_table" "runs" {
  name         = local.runs_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "run_id"

  attribute {
    name = "run_id"
    type = "S"
  }
}

resource "aws_iam_role" "processor" {
  name = "localstack-ops-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "processor" {
  name = "localstack-ops-processor-policy"
  role = aws_iam_role.processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.input.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.runs.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "processor" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_lambda_function" "processor" {
  filename         = data.archive_file.processor.output_path
  function_name    = "localstack-ops-processor"
  role             = aws_iam_role.processor.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 10
  source_code_hash = data.archive_file.processor.output_base64sha256

  environment {
    variables = {
      RUNS_TABLE = aws_dynamodb_table.runs.name
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}

resource "aws_s3_bucket_notification" "input" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "health/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

output "input_bucket" {
  value = aws_s3_bucket.input.bucket
}

output "runs_table" {
  value = aws_dynamodb_table.runs.name
}
