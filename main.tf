provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

# Create S3 bucket
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "solace-mi-test" # Change to your desired bucket name
}

# Configure bucket ownership
resource "aws_s3_bucket_ownership_controls" "sftp_bucket_ownership" {
  bucket = aws_s3_bucket.sftp_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Configure bucket ACL
resource "aws_s3_bucket_acl" "sftp_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.sftp_bucket_ownership]
  bucket     = aws_s3_bucket.sftp_bucket.id
  acl        = "private"
}

# Create IAM role for AWS Transfer Family
resource "aws_iam_role" "transfer_role" {
  name = "transfer-server-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for AWS Transfer Family
resource "aws_iam_policy" "transfer_policy" {
  name        = "transfer-server-iam-policy"
  description = "Policy for AWS Transfer Family to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.sftp_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObjectVersion",
          "s3:GetObjectACL",
          "s3:PutObjectACL"
        ]
        Resource = "${aws_s3_bucket.sftp_bucket.arn}/*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "transfer_policy_attachment" {
  role       = aws_iam_role.transfer_role.name
  policy_arn = aws_iam_policy.transfer_policy.arn
}

# Create AWS Transfer Family server
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.transfer_role.arn
  protocols              = ["SFTP"]

  endpoint_type = "PUBLIC" # Can be changed to VPC for enhanced security
}

# Create a user for the Transfer server
resource "aws_transfer_user" "sftp_user" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = "solace-mi-user" # Change to desired username
  role      = aws_iam_role.transfer_role.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.sftp_bucket.id}"
  }
}

# Create SSH key for the user (in production, use a proper key management approach)
resource "aws_transfer_ssh_key" "sftp_user_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = "" # Replace with your actual public SSH key
}

# Outputs
output "sftp_endpoint" {
  value       = aws_transfer_server.sftp_server.endpoint
  description = "SFTP server endpoint"
}

output "sftp_user" {
  value       = aws_transfer_user.sftp_user.user_name
  description = "SFTP username"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.sftp_bucket.id
  description = "S3 bucket name for SFTP"
}
