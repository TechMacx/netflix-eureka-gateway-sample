###################
## Common variables
###################
variable "infra_env" {
  type    = string
  default = "prod"
}

variable "proj_name" {
  type    = string
  default = "nuestro"
}

variable "domain_name" {
  type    = string
  default = "nuestro.live"
}

variable "cluster_name" {
  description = "The AWS PRIMARY region as Cluster"
  type        = string
  default     = "prs"
}

#######################
## used in providers.tf
#######################
variable "aws_region" {
  description = "The AWS region things are created in"
  default     = "us-east-1"
}

##################################
## used in network.tf (VPC module)
##################################
variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.91.0.0/16"
}

variable "subnet_cidr_block" {
  type        = string
  description = "The IP range to use for the VPC subnets"
  default     = "8"
}

# #################################################
# ## used in API gateway cognito post authorization
# #################################################

## Post Login scripts for Cognito EMAIL verification 
variable "ses_email_addresses" {
  description = "Create SES emails with these email ids"
  type        = list(string)

  default = ["aritra.biswas@arpiantech.com", "raj@gometapixel.com"] // new email id should be added at the END of the LIST

}
