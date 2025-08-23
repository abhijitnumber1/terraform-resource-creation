provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "example" {
  ami           = "ami-0a7d80731ae1b2435"
  instance_type = "t2.micro"
  tags = {
    Name = "TerraformInstance"
  }
}

## create a custom VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraform Custom VPC"
  }
}
## create a custom subnet
resource "aws_subnet" "custom_subnet" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Terraform Custom Subnet"
  }
}