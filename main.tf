provider "aws" {
  region = "us-west-2"
}

# vpc block

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name="Try-vpc"
  }
}

# gets the list of all AZ
data "aws_availability_zones" "all" {}

# Public subnet

resource "aws_subnet" "public-az-1" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.subnet1_cidr

  tags = {
    Name="Public Subnet "
  }
}

# creating a internet Gateway

resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "Internet Gateway"
  }
}

# Route table for public subnet
resource "aws_route_table" "my_vpc_public" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_vpc_igw.id
    }

    tags = {
        Name = " Public RouteTable"
    }
}

resource "aws_instance" "server" {
   ami           = var.amiid
   instance_type = var.type
   key_name      = var.pemfile
   vpc_security_group_ids = [aws_security_group.instance.id]
   subnet_id = aws_subnet.public-az-1.id
   availability_zone = data.aws_availability_zones.all.names[0]
   
   associate_public_ip_address = true
   
   user_data = <<-EOF
               #!/bin/bash
               echo '<html><body><h1 style="font-size:50px;color:blue;">WEZVA TECHNOLOGIES (ADAM) <br> <font style="color:red;"> www.wezva.com <br> <font style="color:green;"> +91-9739110917 </h1> </body></html>' > index.html
               nohup busybox httpd -f -p 8080 &
              EOF

    tags = {
        Name = "Web Server"
    }
  
}

# security group for EC2

resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.my_vpc.id
  name = "Instance -1 "

  # Allowing all outbound connection

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inboud ssh connection
  ingress = [{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  #Inbound for web server
  {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

# Private subnet on second AZ

resource "aws_subnet" "private-az-2" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.subnet2_cidr

  tags = {
    Name="Private Subnet "
  }
}

# Route table for DB

resource "aws_route_table" "my_vpc_private"{
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.server.primary_network_interface_id
  }
  tags = {
    name="private route table"
  }
}

# route table subnet association

resource "aws_route_table_association" "public-az-1" {
  subnet_id = aws_subnet.public-az-1.id
  route_table_id = aws_route_table.my_vpc_public.id
}

resource "aws_security_group" "db" {
  name = "example-db"
  vpc_id = aws_vpc.my_vpc.id

  # Allow all outbound 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound for SSH
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.instance.id]
  }
  
}

resource "aws_instance" "db" {
   ami           = var.amiid
   instance_type = var.type
   key_name      = var.pemfile
   vpc_security_group_ids = [aws_security_group.db.id]
   subnet_id = aws_subnet.private-az-2.id
   availability_zone = data.aws_availability_zones.all.names[1]
   
   associate_public_ip_address = true

   tags = {
       Name = "DB Server "
   }
  
}