# Output

output "mt-lab_vpc_id_output" {
  value = aws_vpc.mt-lab_vpc_cidr
}

output "mt-lab_available_azs_output" {
  value = data.aws_availability_zones.mt-lab_available_azs.names[1]
}