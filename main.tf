terraform {
  /*
  cloud {
    organization = "warangal"

    workspaces {
      name = "provisioners"
    }
  }*/
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "main" {
  id = "vpc-07946ff61abbd211c"
}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}
resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  description = "Allow ssh and http traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "http traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }
  ingress {
    description      = "ssh traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyJbp78JJQ5tU2Sepst6zFy66r4NtC4zxrBT7kvLO+Peymr5KbfAF2YQaOp4S7o5quh1EfCT7L/+Xg3Jv8DqNrpHakoPENcXKlTYXgh6KX61Nay0d5mogATOUTiaWaa76645Y7If8ZgHg+5filf/776T9NAbzfYNEBFn7MUPGREsJVWO9JpbguvrbAgO7b3DGczZbiZ/usQLnQq2UyCe5HIwnNBr/L+2/F8+LKmZhc+q5NoVJAXATXS/4MuFkpc9LTiUXX1ZBlYQDcNIsjoTpxL/QBTw4l8gvUogi5J2bX8n+kETBf/+4XS4B6oWXXSZdU7E1v42qTutytqG8wT9aCgZqtAw+0A662+GVYa1Jo/+6J28kvf99b2sI1srgLIf4IMIEHUkYaYpNbH4ijnMp5dWktzow9t6i4w6RsPkEsFEGs1dQD58JoimJOvhrVeokGIzkUfc1d6TY8B5PagP09iw/sB6fCdii7vtmQV3fQnrAZHtJOYFIG95aoL1OTN2M= reddy@DESKTOP-MRVPVPL"
}

resource "aws_instance" "web_server" {
  ami                    = "ami-01107263728f3bef4"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  user_data              = data.template_file.user_data.rendered
  provisioner "file" {
    content     = "mars"
    destination = "/home/ec2-user/abc.txt"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/reddy/.ssh/terraform")
      host        = self.public_ip
    }
  }
  tags = {
    Name = "web_server"
  }
}

resource "null_resource" "temp_res" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.web_server.id}"

  }
  depends_on = [aws_instance.web_server]

}

output "public_ip_address" {
  value = aws_instance.web_server.public_ip
}