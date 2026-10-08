# PROVIDED - same shape as Chapter 7's network, slimmed to 2 AZs and 1 NAT gateway
# (a NAT per AZ is the production choice; one keeps the lab cheap).
# Layout per Fig 8.3: worker nodes live in PRIVATE subnets, the NLB in PUBLIC ones.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-${local.prefix}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw-${local.prefix}" }
}

resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name                                          = "snet-public-${count.index}-${local.prefix}"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  tags = {
    Name                                          = "snet-private-${count.index}-${local.prefix}"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "eip-nat-${local.prefix}" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "nat-${local.prefix}" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security groups referenced by vpc_config in the book's aws_eks_cluster.
resource "aws_security_group" "cluster" {
  name        = "sg-${local.prefix}-cluster"
  description = "EKS control plane ENIs"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "cluster_nodes" {
  name        = "sg-${local.prefix}-nodes"
  description = "EKS worker nodes"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_nodes" {
  security_group_id            = aws_security_group.cluster_nodes.id
  referenced_security_group_id = aws_security_group.cluster_nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  security_group_id            = aws_security_group.cluster_nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster_nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.cluster_nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
