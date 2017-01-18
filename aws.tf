provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-west-1"
}

resource "aws_instance" "example" {
    ami = "ami-0d729a60"
    instance_type = "t2.micro"
}
