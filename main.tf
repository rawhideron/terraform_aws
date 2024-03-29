

provider "aws" {
  region = "us-east-1"
}
variable "server_port" {
  description = "No comment"
  type        = number
  default     = 80
}


data "aws_vpc" "default" {
  default = true
}


data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id

}



resource "aws_launch_configuration" "example2" {
  image_id        = "ami-02e136e904f3da870"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
			#!/usr/bin/bash
			sudo yum install -y httpd &&
			sudo systemctl start httpd &&
			sudo systemctl enable httpd &&
			echo "Hello, World" > index.html
			EOF
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "example2" {
  launch_configuration = aws_launch_configuration.example2.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example2"
    propagate_at_launch = true

  }

}
resource "aws_lb" "example2" {
  name               = "terraform-asg-example2"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]

}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example2.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {

      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn

  }
}
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance2"
  tags = {
    Name = "terraform-example2"
  }


  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

output "alb_dns_name" {
  value       = aws_lb.example2.dns_name
  description = "The domain of the load balancer"
}
