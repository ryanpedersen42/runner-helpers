variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC for deployment"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy into"
  type        = string
}

variable "key_name" {
  description = "name of your AWS key name (should be <key-name>.pem)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string 
}

variable "private_key_path" {
  description = "Path to private key file for AWS"
  type        = string
}

variable "runner_install_script" {
  type        = string
  default     = "../runner-scripts/install-runner.sh"
  description = "Specifies the install_runner.sh script file path"
}

variable "runner_platform" {
  type        = string
  default     = "linux/amd64"
  description = "Defines the runner architecture platform - tested on linux/amd64"
}

variable "runner_name" {
  type        = string
  description = "Name of your runner, i.e. <your-namespace>/<this-is-your-runner-name>"
}

variable "runner_token" {
  type        = string
  description = "The CircleCI Runner token from the CLI"
}