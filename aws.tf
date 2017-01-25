provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-west-1"
}

resource "aws_vpc" "morgan-vpc" {
  cidr_block = "10.0.0.0/16"
  tags {
    owner = "andrew-morgan"
    name = "etcd-vpc"
  }
}

resource "aws_subnet" "subnet" {
    count = 3

    vpc_id = "${aws_vpc.morgan-vpc.id}"
    cidr_block = "${cidrsubnet("10.0.0.0/16", 8, count.index)}"
    availability_zone = "${element(var.zones, count.index)}"
    map_public_ip_on_launch = true

    tags {
      owner = "andrew-morgan"
      name = "etcd-subnet-${count.index}"
    }
}

resource "aws_instance" "instance" {
  count = 3

  ami = "ami-1967056a"
  instance_type = "t2.micro"
  subnet_id = "${element(aws_subnet.subnet.*.id, count.index)}"
  private_ip = "${cidrhost("${element(aws_subnet.subnet.*.cidr_block, count.index)}", 4)}"
  depends_on = ["aws_internet_gateway.gw"]
  security_groups = ["${aws_security_group.sg.id}"]
  key_name = "${aws_key_pair.deployer.id}"

  tags {
    owner = "andrew-morgan"
    name = "etcd-node-for-subnet-${count.index}"
  }
}

resource "aws_key_pair" "deployer" {
    key_name = "andrew-deployer-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCv97yQNdOSH+XPc9OdpdZPYVDH58c2HjwLv3KDStyuEk47T/E05gm7b0jeUwNQfnfRRJGH7LFK2nl6Km8Da/08Vlev+BG8O42M5gM6oLAeJY1zvAC+3fQ9kJAThyCj4Paz7uFpezy3GdPOx13gAqhlzLI8iDioz+lVQIXSxFS+INuw54d2L/DbPIXglQMYZ/4sQpP0q9Vn7gYX2Yg1PX3xUrd9bRp3P60d3YLgoooblMh6JByqjiWi090oUxhx8YnpU5VWjtYKe/r+skWbKOEELE3O1+HwlAaZNDtFJZYapov9Z/wZ4JTtV+PJrR9ZCDA/HWocZaQT/CGmqHw3zlKz andrewmorgan1@Andrews-MacBook-Pro.local"
}

resource "aws_eip" "eip" {
  count = 3

  vpc = true
  instance = "${element(aws_instance.instance.*.id, count.index)}"
  associate_with_private_ip = "${element(aws_instance.instance.*.private_ip, count.index)}"
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.morgan-vpc.id}"

    tags {
      owner = "andrew-morgan"
      name = "etdc-internet-gateway"
    }
}

resource "aws_route_table" "rt" {
  vpc_id  = "${aws_vpc.morgan-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "morgan-rt"
  }
}

resource "aws_route_table_association" "rt_association" {
    count = 3

    subnet_id = "${element(aws_subnet.subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_security_group" "sg" {
    name = "morgan-security-group"
    description = "security group for VPC"
    vpc_id = "${aws_vpc.morgan-vpc.id}"

    ingress {
      from_port = 2379
      to_port = 2379
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["217.138.34.2/32"]
    }

    tags {
      Name = "morgan-security-group"
    }
}
