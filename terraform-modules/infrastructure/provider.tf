provider "aws" {
  region   = "ap-southeast-2"
  assume_role {
    role_arn = "arn:aws:iam::778196150762:role/TerraformInCodeBuild"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias    = "usea1"
  region   = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::778196150762:role/TerraformInCodeBuild"
  }

  default_tags {
    tags = local.tags
  }
}