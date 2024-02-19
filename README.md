# Using the terraform-workspaces
## TF Workspaces to separate TF state data

**Using the terraform module with default workspace -** 

- **The information about all the resources managed by Terraform is stored in a state file. It is important to store this state file in a secure location.**
- **Every Terraform run is associated with a state file for validation and reference purposes.**
- **Any modifications to the Terraform configuration, planned or applied, are always validated first with references in the state files, and the execution result is updated back to it.**
- **If you are not consciously using any workspace, all of this already happens in a default workspace.**

**Example -** 

Suppose we have 100 AWS account. 

If we mess up the state file, everything gone, hard to troubleshoot, hard to maintain.

Every time we change the terraform for one env, it will scan & talk to every account. Then the network traffic will be high for no reason.

## **What if we split the state file for each env to avoid those kinds of issues!!!**

<aside>
💡 Workspaces allow users to manage different sets of infrastructure using the same configuration by isolating state files.

</aside>

<aside>
💡 A common use for multiple workspaces is to create a parallel, distinct copy of a set of infrastructure to test a set of changes before modifying production infrastructure.

</aside>

In this lab, we will use separate workspaces to split the state file for Master & Dev. 

We will just create VPC & CIDR for the testing purpose. 

We will use assumed role to create AWS resources. 

We will apply terraform in each workspace.

1) We will use AWS master account to connect to AWS env using terraform.

- .aws/config
    
    ```yaml
    [profile mt-lab-master-mgmt]
    region = ap-southeast-1
    output = json
    ```
    
- .aws/credentials
    
    ```yaml
    [mt-lab-master-mgmt]
    aws_access_key_id = AKIxxxxxxxxxL
    aws_secret_access_key = kG3dZxxxxxxxxxxxxxxxxxxxxxxxxxpDCKSp
    ```
    

2) Create a new role in master account & trust to master account itself / Create a new role in dev account & trust to master account.

![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/c1627e1e-7d65-4bd9-9cbd-31a0f5f08bcd)

![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/81e1bb74-62ab-46fe-ba30-f5fbe4e5135f)




We will use those assumed roles to create AWS resources. 


3) Prepare the terraform code to create VPC & AZ.


- versions.tf
    
    ```yaml
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
      assume_role {
        role_arn = var.provider_env_assumed_role[terraform.workspace]
      }
      region = var.mt-lab_aws_region
    }
    ```


- variables.tf
    
    ```yaml
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
        "mt-lab-master-mgmt"   = "arn:aws:iam::0582642xxxxx:role/mt-lab-master-terraform-role"
        "mt-lab-master-dev"       = "arn:aws:iam::7673979xxxxx:role/mt-lab-dev-terraform-role"
      #  "gritworks-security"  = "arn:aws:iam::9819890xxxxx:role/gritworks-security-terraform-role"
      }
    }
    ```

        

- main.tf
    
    ```yaml
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
    ```
    

- output.tf
    
    ```yaml
    # Output
    
    output "mt-lab_vpc_id_output" {
      value = aws_vpc.mt-lab_vpc_cidr
    }
    
    output "mt-lab_available_azs_output" {
      value = data.aws_availability_zones.mt-lab_available_azs.names[1]
    }
    ```
    

4) Create workspaces.

```yaml
vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace list
* default

vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace new mt-lab-master-mgmt
Created and switched to workspace "mt-lab-master-mgmt"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace new mt-lab-dev-mgmt
Created and switched to workspace "mt-lab-dev-mgmt"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.

vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace list
  default
* mt-lab-dev-mgmt
  mt-lab-master-mgmt

```

5) Switch the workspace to Master & apply the terraform in Master env.

vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace select mt-lab-master-mgmt
Switched to workspace "mt-lab-master-mgmt".


![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/050bd494-25d0-4a27-b527-10e4fd31db66)



Let’s verify VPC is created in Master env. 

![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/ccd10d1b-5175-45ad-8e2d-e9027e347fe9)



6) Switch the workspace to Dev & apply the terraform in Dev env

```yaml
vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace select mt-lab-dev-mgmt
Switched to workspace "mt-lab-dev-mgmt".
vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform workspace list
  default
* mt-lab-dev-mgmt
  mt-lab-master-mgmt

vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform plan
vagrant@kindcluster-box:~/tf-demo/terraform-workspaces$ terraform apply
```

Let’s verify the VPC is created in Dev env. 

![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/d53a5b84-1c8e-481d-9b0f-274e0725582d)



7) Now we have two state files for master & dev workspaces. 

![image](https://github.com/myathway-lab/Using-terraform-workspaces/assets/157335804/8115171e-9e6d-4e83-a43d-1850482eff3f)



8) We can use tfvars file to override the variables inside variables.tf. 

- master-variables.tfvars
    
    ```
    mt-lab_aws_region = "ap-southeast-0"
    mt-lab_vpc_cidr = "172.16.0.0/16"
    ```
    
    ```yaml
    terraform plan -var-file master-variables.tfvars
    terraform apply -var-file master-variables.tfvars
    ```
    
- dev-variables.tfvars
    
    ```
    mt-lab_aws_region = "ap-southeast-2"
    mt-lab_vpc_cidr = "192.168.0.0/16"
    ```
    
    ```yaml
    terraform plan -var-file dev-variables.tfvars
    terraform apply -var-file dev-variables.tfvars
    ```

