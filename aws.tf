provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-west-1"
}

resource "aws_vpc" "morgan-vpc" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "terraform-aws-morgan-vpc"
  }
}

resource "aws_subnet" "subnet" {
    count = 3

    vpc_id = "${aws_vpc.morgan-vpc.id}"
    cidr_block = "${cidrsubnet("10.0.0.0/24", 8, count.index)}"
    availability_zone = "${element(var.zones, count.index)}"
    map_public_ip_on_launch = true

    tags {
      owner = "andrew-morgan"
      name = "subnet-${count.index}"
    }
}

resource "aws_instance" "etcd-node-a" {
  ami = "ami-1967056a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.0.id}"
  private_ip = "10.0.0.4"
  depends_on = ["aws_internet_gateway.gw"]
  security_groups = ["${aws_security_group.sg.id}"]
  key_name = "${aws_key_pair.deployer.id}"

  tags {
    Name = "morgan-etc-instance-a"
  }
}

resource "aws_instance" "etcd-node-b" {
  ami = "ami-1967056a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.1.id}"
  private_ip = "10.0.1.4"
  depends_on = ["aws_internet_gateway.gw"]
  security_groups = ["${aws_security_group.sg.id}"]
  key_name = "${aws_key_pair.deployer.id}"

  tags {
    Name = "morgan-etc-instance-b"
  }
}

resource "aws_instance" "etcd-node-c" {
  ami = "ami-1967056a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.2.id}"
  private_ip = "10.0.2.4"
  depends_on = ["aws_internet_gateway.gw"]
  security_groups = ["${aws_security_group.sg.id}"]
  key_name = "${aws_key_pair.deployer.id}"

  tags {
    Name = "morgan-etc-instance-c"
  }
}

resource "aws_key_pair" "deployer" {
    key_name = "andrew-deployer-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCv97yQNdOSH+XPc9OdpdZPYVDH58c2HjwLv3KDStyuEk47T/E05gm7b0jeUwNQfnfRRJGH7LFK2nl6Km8Da/08Vlev+BG8O42M5gM6oLAeJY1zvAC+3fQ9kJAThyCj4Paz7uFpezy3GdPOx13gAqhlzLI8iDioz+lVQIXSxFS+INuw54d2L/DbPIXglQMYZ/4sQpP0q9Vn7gYX2Yg1PX3xUrd9bRp3P60d3YLgoooblMh6JByqjiWi090oUxhx8YnpU5VWjtYKe/r+skWbKOEELE3O1+HwlAaZNDtFJZYapov9Z/wZ4JTtV+PJrR9ZCDA/HWocZaQT/CGmqHw3zlKz andrewmorgan1@Andrews-MacBook-Pro.local"
}

resource "aws_eip" "a" {
  vpc = true
  instance = "${aws_instance.etcd-node-a.id}"
  associate_with_private_ip = "10.0.0.4"
}

resource "aws_eip" "b" {
  vpc = true
  instance = "${aws_instance.etcd-node-b.id}"
  associate_with_private_ip = "10.0.1.4"
}

resource "aws_eip" "c" {
  vpc = true
  instance = "${aws_instance.etcd-node-c.id}"
  associate_with_private_ip = "10.0.2.4"
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.morgan-vpc.id}"

    tags {
      Name = "morgan-igw"
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

resource "aws_route_table_association" "rt_association_a" {
    subnet_id = "${aws_subnet.subnet.0.id}"
    route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_route_table_association" "rt_association_b" {
    subnet_id = "${aws_subnet.subnet.1.id}"
    route_table_id = "${aws_route_table.rt.id}"
}

/*resource "aws_route_table_association" "rt_association_c" {
    subnet_id = "${aws_subnet.subnet.2.id}"
    route_table_id = "${aws_route_table.rt.id}"
}*/

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
