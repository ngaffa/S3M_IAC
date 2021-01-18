resource "aws_vpc" "s3m-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
     tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

# TODO: figure out how to support creating multiple subnets, one for each
# availability zone.
resource "aws_subnet" "s3m-public" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.availability_zone_1
     tags = {
    "name"="s3m-public"
    "project" = "S3M"
    "tuto"="medium"
  }
}
resource "aws_subnet" "s3m-private-1" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = var.availability_zone_2
    tags = {
    "name"="s3m-private"
    "project" = "S3M"
    "tuto"="medium"
  }
}
resource "aws_subnet" "s3m-private-2" {
    vpc_id = aws_vpc.s3m-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = var.availability_zone_3
    tags = {
    "name"="s3m-private"
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_internet_gateway" "s3m-igw" {
    vpc_id = aws_vpc.s3m-vpc.id
}

resource "aws_eip" "s3m-eip_nat_gateway" {
  vpc = true
}


resource "aws_nat_gateway" "s3m-ngw" {
  allocation_id = aws_eip.s3m-eip_nat_gateway.id
  subnet_id     = aws_subnet.s3m-public.id
  tags = {
    "project" = "S3M"
    "tuto"="medium"
  }
}

resource "aws_default_route_table" "s3m-rt-public" {
default_route_table_id = aws_vpc.s3m-vpc.default_route_table_id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.s3m-igw.id
    }
}

resource "aws_route_table" "s3m-rt-private" {
    vpc_id = aws_vpc.s3m-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.s3m-ngw.id
    }
}

resource "aws_route_table_association" "s3m-rta-private-1" {
    subnet_id = aws_subnet.s3m-private-1.id
    route_table_id = aws_route_table.s3m-rt-private.id
}


resource "aws_route_table_association" "s3m-rta-private-2" {
    subnet_id = aws_subnet.s3m-private-2.id
    route_table_id = aws_route_table.s3m-rt-private.id
}
