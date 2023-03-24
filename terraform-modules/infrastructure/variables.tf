variable "content_bucket_name" {
  type        = string
  nullable    = false
  description = "Name of the bucket that will serve the content"
}

variable "hosted_zone_name" {
  type        = string
  nullable    = false
  description = "Name of the hosted that will serve the content"
}
