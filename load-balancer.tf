resource "aws_lb" "s3m-nlb" {
  name                       = "s3mnlb"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = [aws_subnet.s3m-private-1.id, aws_subnet.s3m-private-2.id]
  enable_deletion_protection = false

  tags = {
    "project" = "S3M"
    "tuto"    = "medium"
  }
}

resource "aws_lb_target_group" "s3m-tg" {
  name        = "s3m-nlb-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.s3m-vpc.id
  tags = {
    "project" = "S3M"
    "tuto"    = "medium"
  }
}

# Forward TCP apiserver traffic to containers
resource "aws_lb_listener" "s3m-container-listner" {
  load_balancer_arn = aws_lb.s3m-nlb.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.s3m-tg.arn
  }
}