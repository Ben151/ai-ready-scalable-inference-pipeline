# 1. Security Group for EFS to allow NFS traffic exclusively from the ASG servers
resource "aws_security_group" "efs_sg" {
  name        = "efs-security-group"
  description = "Allow NFS (port 2049) access strictly from the ASG security group"
  vpc_id      = aws_vpc.main.id

  # Allow port 2049 (NFS) only from the backend ASG security group
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "efs-sg" }
}

# 2. The EFS File System itself (shared storage for AI models and data)
resource "aws_efs_file_system" "ai_storage" {
  creation_token   = "ai-inference-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true # Security best practice

  tags = { Name = "AI-Model-Storage" }
}

# 3. EFS Mount Target for Private Subnet 1 (AZ1)
resource "aws_efs_mount_target" "mount_az1" {
  file_system_id  = aws_efs_file_system.ai_storage.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

# 4. EFS Mount Target for Private Subnet 2 (AZ2)
# (assuming you created aws_subnet.private_2 in AZ2)
resource "aws_efs_mount_target" "mount_az2" {
  file_system_id  = aws_efs_file_system.ai_storage.id
  subnet_id       = aws_subnet.private_2.id 
  security_groups = [aws_security_group.efs_sg.id]
}