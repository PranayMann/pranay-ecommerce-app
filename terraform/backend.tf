terraform {
  backend "s3" {
    bucket               = "tf-state-pranay-eks"
    workspace_key_prefix = "workspace"
    region               = "ap-south-1" # bucket region
    key                  = "test-cluster/terraform.tfstate"
    encrypt              = true
  }
}