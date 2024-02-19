variable "mt-lab_aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-southeast-1"
}


variable "mt-lab_vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "provider_env_assumed_role" {
  type = map(any)
  default = {
    "mt-lab-master-mgmt" = "arn:aws:iam::058264206195:role/mt-lab-master-terraform-role"
    "mt-lab-dev-mgmt"  = "arn:aws:iam::767397933373:role/mt-lab-dev-terraform-role"
    #  "gritworks-security"  = "arn:aws:iam::981989025184:role/gritworks-security-terraform-role"
  }
}