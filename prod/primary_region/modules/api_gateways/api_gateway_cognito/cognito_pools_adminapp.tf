##################################
### COGNITO USER POOL for adminapp
##################################
## Create cognito pool id
resource "aws_cognito_user_pool" "adminapp-pool" {
  name = "${var.infra_env}-${var.proj_name}-adminapp-pool"

  ## ---------[Attributes]--------------
  username_attributes = ["email"] // How do you want your end users to sign in?
  username_configuration {
    case_sensitive = false
  }
  schema { // Which standard attributes are required? 
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  ## ---------[Policies]-----------------
  password_policy { // What password strength do you want to require?
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  ## ---------[MFA and verifications]--------------
  mfa_configuration = "ON"           // Do you want to enable Multi-Factor Authentication (MFA)?
  software_token_mfa_configuration { // Which second factors do you want to enable?
    enabled = true
  }
  account_recovery_setting { // How will a user be able to recover their account?
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    # recovery_mechanism { 
    #   name     = "verified_phone_number"
    #   priority = 2
    # }
  }
  auto_verified_attributes = ["email"] // Which attributes do you want to verify?

  ## ---------[Triggers : Lambda]--------------
  # lambda_config {
  #   post_authentication = aws_lambda_function.post-login.arn // Do you want to customize workflows with triggers?
  # }
  # depends_on = [aws_lambda_function.post-login]
}

## Create "app clients" for adminapp and added to existing cognito user pool
## The app clients that you add below will be given a unique ID and an optional secret key to access this user pool.
resource "aws_cognito_user_pool_client" "adminapp-pool-client" {
  name         = "${var.infra_env}-${var.proj_name}-adminapp-client"
  user_pool_id = aws_cognito_user_pool.adminapp-pool.id
}


###########################################
### COGNITO USER POOL for existing adminapp
###########################################

# data "aws_cognito_user_pools" "adminapp-pool" {
#   name = "uat-nuestro-adminapp-pool"
# }

# data "aws_cognito_user_pool_client" "adminapp-pool-client" {
#   client_id    = "7dcvb6dc7vome8n7a51dilvg28"
#   user_pool_id = "us-east-2_mhR6ISza4"
# }