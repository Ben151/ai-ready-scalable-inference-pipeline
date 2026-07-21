# 1. Application Load Balancer (ALB) deployed in Public Subnets across both AZs
resource "aws_lb" "ai_alb" {
  name               = "ai-inference-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "AI-Inference-ALB" }
}

# 2. Target Group for backend instances (listening on port 80/8080)
resource "aws_lb_target_group" "ai_tg" {
  name     = "ai-inference-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "AI-Target-Group" }
}

# 3. HTTP Listener (Port 80) - Directs incoming traffic to the Target Group
# Note: In a production environment, add an HTTPS listener (port 443) using an AWS ACM SSL Certificate.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ai_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_tg.arn
  }
}