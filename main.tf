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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+kRWMnp4cIG1H4Nhfy1fP8QvgJ4HFHJKKn7e6/8sD64BWeD9fiSzhVpDyPu9sVbaPFhYS5xM6mCD1fyzDX5gUlny6b7d13fja0JF8lRYG5N0N4UdWpTH1+8MSadK54hIj7eeT0nSEiNMZaZ0gmGjtaI+mkGdEPcUMOtTKqhOTj4v/TqXfVGaXcnSJjKz31FU0z8XbKyu1AnMzZ/TT3SpkNTqiq0vM9Pzb/NsfW3YXEYYPWihfe5LMrw7s4vvkXXlRH4dx0dejRL4j4N3C5x5+c9veT0E6JUchxpLOWbH1CK1fpfVD+Um9gP9hkiXABsl/eKeVddEFbUvWPwXNDg644sp6fnEpj6UT0MMhYA3rU6a4pDIRLq4iEmTNZB+YS+y7a4jStn5PuLJQ13ky+aowE/mcsKzcAXg51aZLSqeUn8L13DqE4yTSIXk6jk39VCaB5vUwaSZ7fe0tVY6PO4EP/Z+2YR6PFhnO7nQveeLv8tFTKnmWHoUZOR8InHVKE0U= anudeep_reddy@DESKTOP-MRVPVPL"
}

resource "aws_instance" "web_server" {
  ami                    = "ami-01107263728f3bef4"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  user_data              = data.template_file.user_data.rendered
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "C:\\Users\\Anudeep Reddy\\.ssh\\terraform"
      host        = "${self.public_ip}"
    }
  }
  tags = {
    Name = "web_server"
  }
}
output "public_ip_address" {
  value = aws_instance.web_server.public_ip
}