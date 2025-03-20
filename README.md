This project creates an S3 bucket, AWS Transfer Service, and AWS Transfer User allowing for SFTP access over public endpoint to the base S3 bucket.

## Prerequisites

- AWS CLI installed and configured
- The aws cli user has permissions required to create terraform resources
- Existing SSH pub/private key

## Instructions

Run the following commands to provision the S3 bucket

- `terraform init`
- `terraform apply`

Delete Resources (Including files in the S3 bucket)

- `terraform destroy`
