locals {
  provider_alias = terraform.workspace
}

# create vpc
resource "aws_vpc" "mt-lab_vpc_cidr" {
  cidr_block           = var.mt-lab_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${local.provider_alias}-vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "mt-lab_available_azs" {
  state = "available"
}