# Create an IAM role for the EC2 instances in the ASG
resource "aws_iam_role" "instance_role" {
  name = "ai-infra-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic CloudWatch logging policy so instances can send logs
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an Instance Profile to bridge the Role and the EC2 instances
resource "aws_iam_instance_profile" "instance_profile" {
  name = "ai-infra-instance-profile"
  role = aws_iam_role.instance_role.name
}