# 1. Launch Template defining the server configuration and bootstrap script (user_data)
resource "aws_launch_template" "ai_server_lt" {
  name_prefix   = "ai-server-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.asg_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  # User Data script that runs automatically on first boot
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update and install necessary dependencies (Python, Docker, NFS client)
              yum update -y
              yum install -y amazon-efs-utils docker python3

              # Start Docker service
              systemctl start docker
              systemctl enable docker

              # Create mount directory for EFS (Shared AI Models / Storage)
              mkdir -p /mnt/ai-storage

              # Mount the EFS file system using its DNS name
              # Replace with your actual EFS DNS name or fetch dynamically
              mount -t efs -o tls ${aws_efs_file_system.ai_storage.id}:/ /mnt/ai-storage

              # Create a simple Python HTTP server simulating AI Inference to test traffic
              echo "AI Inference Server Running" > index.html
              nohup python3 -m http.server 80 &
              EOF
  )

  tags = { Name = "AI-Server-Template" }
}

# 2. Auto Scaling Group (ASG) maintaining High Availability across private subnets
resource "aws_autoscaling_group" "ai_asg" {
  desired_capacity    = 2
  min_size            = 2
  max_size            = 5
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.ai_tg.arn]

  launch_template {
    id      = aws_launch_template.ai_server_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "AI-Inference-Worker"
    propagate_at_launch = true
  }
}

# 3. Target Tracking Scaling Policy - Keeps CPU utilization around 70%
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "cpu-target-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.ai_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}