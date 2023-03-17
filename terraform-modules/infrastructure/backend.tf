terraform {
    backend "s3" {
        bucket          = "terraform-remote-state-inventory"
        key             = "portfolio/infrastructure/terraform.tfstate"
        region          = "ap-southeast-2"
        dynamodb_table  = "terraform-remote-state-inventory"
        encrypt         = false
        profile         = "amiel"
    }
}