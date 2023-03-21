terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "4.59.0"
      }
      random = {
        source  = "hashicorp/random"
        version = "3.4.3"
      }
    }
}