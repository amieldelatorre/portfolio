provider "aws" {
  region   = "ap-southeast-2"
  # profile  = "{your_profile}" # For use when running locally
  assume_role { # For use by pipeline
    role_arn = "arn:aws:iam::778196150762:role/TerraformInCodeBuild" 
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias    = "usea1"
  region   = "us-east-1"
  # profile  = "{your_profile}" # For use when running locally
  assume_role { # For use by pipeline
    role_arn = "arn:aws:iam::778196150762:role/TerraformInCodeBuild"
  }

  default_tags {
    tags = local.tags
  }
}