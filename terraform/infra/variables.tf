variable "application_name" {
  type    = string
  default = "raskur"
}

variable "environment_name" {
  type    = string
  default = "dev"
}

variable "primary_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "node_size" {
  type    = string
  default = "t3.small"
}

variable "node_image_type" {
  type    = string
  default = "AL2023_x86_64_STANDARD"
}

# IAM *user names* (must already exist) that get ECR push rights, e.g. the user
# whose keys GitHub Actions uses. Empty = nobody (membership resource still valid).
variable "ecr_image_pushers" {
  type    = list(string)
  default = []
}

# These two MUST match what the k8s workspace creates (book: the trust policy
# points at a namespace + service account that do not exist yet).
variable "k8s_namespace" {
  type    = string
  default = "raskur"
}

variable "k8s_service_account_name" {
  type    = string
  default = "raskur-workload-identity"
}
