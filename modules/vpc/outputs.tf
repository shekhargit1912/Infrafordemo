output "vpc_id" {
  value = aws_vpc.vpc.id
}

# output "vpc_ip" {
#   value = aws_vpc.vpc.cidr_block
# }

# output "public_subnet_ids" {
#   value = aws_subnet.public_subnet[*].id
# }

# output "private_subnet_ids" {
#   value = aws_subnet.private_subnet[*].id
# }
