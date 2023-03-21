provider "aws" {
  region    = "ap-southeast-2"
  profile   = "amiel"

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias     = "usea1"
  region    = "us-east-1"
  profile   = "amiel"

  default_tags {
    tags = local.tags
  }
}