

	provider "aws" {
		region = "us-east-1"
	}

	resource "aws_instance" "example" {
		ami = "ami-02e136e904f3da870"
		instance_type = "t2.micro"
		tags = {
			Name = "terraform-example"
		user_data = <<-EOF
			#!/bin/bash
			echo "Hello, World" > index.html
			nohup busybox httpd -f -p 8080 &
			EOF
		}
	}


