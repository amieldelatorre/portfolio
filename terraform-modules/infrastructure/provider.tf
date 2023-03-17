provider "aws" {
  region    = "ap-southeast-2"
  profile   = "amiel"

  default_tags {
    tags = local.tags
  }
}