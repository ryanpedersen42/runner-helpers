terraform {
  required_version = "~> 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_security_group" "sg_22_443" {
  name   = "runner_terraform_sg"
  vpc_id = var.vpc_id

  # to SSH in
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # to look for work
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = var.subnet_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true

  tags = {
    Name = "runner-testing"
  }

  connection {
    host        = self.public_ip
    user        = "ubuntu"
    type        = "ssh"
    private_key = file(var.private_key_path)
    timeout     = "5m"
  }

  #Upload runner provisioner script
  provisioner "file" {
    source      = var.runner_install_script
    destination = "/tmp/install-runner.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "chmod +x /tmp/install-runner.sh",
      "sudo /tmp/install-runner.sh ${var.runner_name} ${var.runner_token} ${var.runner_platform}"
    ]
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}