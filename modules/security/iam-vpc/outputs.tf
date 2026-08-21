output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "lab_role_arn" {
  value = aws_iam_role.lab.arn
}

output "lab_role_name" {
  value = aws_iam_role.lab.name
}

output "lab_instance_profile_name" {
  value = aws_iam_instance_profile.lab.name
}
