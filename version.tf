terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.12.0"
    }
  }
}

# provider "aws" {
#   shared_config_files      = ["/home/vagrant/.aws/config"]
#   shared_credentials_files = ["/home/vagrant/.aws/credentials"]
#   profile                  = "gritworks-nonprod"
#   alias                    = "gritworks-nonprod"
#   region                   = var.gritworks_nonprod_aws_region
# }

provider "aws" {
  profile = "mt-lab-master-mgmt" # this line is requried. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade#changes-to-authentication
  # alias   = "gritworks-dev"
  assume_role {
    role_arn = var.provider_env_assumed_role[terraform.workspace]
  }
  region = var.mt-lab_aws_region
}