

	provider "aws" {
		region = "us-east-1"
	}
	variable "server_port" {
		description = "No comment"
		type = number
		default = 8080
	}
	resource "aws_instance" "example" {
		ami = "ami-02e136e904f3da870"
		instance_type = "t2.micro"
		vpc_security_group_ids = [aws_security_group.instance.id]
		tags = {
			Name = "terraform-example"
		user_data = <<-EOF
			#!/bin/bash
			echo "Hello, World" > index.html
			nohup busybox httpd -f -p 8080 &
			EOF
		}
	}

	resource "aws_security_group" "instance" {
		name = "terraform-example-instance"
		ingress {
			from_port = var.server_port
			to_port = var.server_port
			protocol = "tcp"
			cidr_blocks = ["0.0.0.0/0"]

		}
	}


