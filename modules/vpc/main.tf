#craete the vpc

resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    assign_generated_ipv6_cidr_block = false
    instance_tenancy = "default"
    tags = {
        Name = "vpc-${var.project_name}"
    }
  
}

#create the internet gateway abd attach it to the vpc

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.project_name}-igw"
    }
  
}

data "aws_availability_zones" "available_zones" {}


#create the public subnets in each availability zone

resource "aws_subnet" "public_subnets" {
  #count = length(data.aws_availability_zones.available_zones.names)
  count = length(var.public_subnet_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}
#create the route table for the public subnets


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  
}

tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

#associate the public subnets with the route table

resource "aws_route_table_association" "public_subnet_route_table_association" {
  #count = length(data.aws_availability_zones.available_zones.names)
  count = length(var.public_subnet_cidr)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

#craete the private subnets in each availability zone

resource "aws_subnet" "private_subnets" {
  #count = length(data.aws_availability_zones.available_zones.names)
    count = length(var.private_subnet_cidr)


  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
  
}

#create the new elastic IP for the NAT gateway

resource "aws_eip" "eip_for_nat_gateway" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-gatway"
  }
}

#create the NAT gateway in public subnets

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip_for_nat_gateway.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, var.index)

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [ aws_internet_gateway.internet_gateway ]
  
}

## create private route table and add route through nat gateway
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }
    tags = {
        Name = "${var.project_name}-private-route-table"
    }
    }
# make the private route table as main route table
resource "aws_main_route_table_association" "aws_main_route_table" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.private_route_table.id
}


#associate private subnet 1 with "private route table"
resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  
  #count          = length(data.aws_availability_zones.available_zones.names)
    count = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}


