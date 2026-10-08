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

# ---- inputs that come from the infra workspace outputs (Fig 8.12) ----
variable "eks_cluster_name" {
  type = string
}

variable "ecr_repository_name" {
  type        = string
  description = "Repository NAME (not URL), e.g. ecr-raskur-dev-raskur"
}

variable "workload_identity_role" {
  type        = string
  description = "ARN of the IAM role the service account assumes"
}

variable "image_tag" {
  type        = string
  description = "Container image tag pushed by docker build, e.g. 2026.10.1"
}

# must equal the infra workspace values
variable "k8s_namespace" {
  type    = string
  default = "raskur"
}

variable "k8s_service_account_name" {
  type    = string
  default = "raskur-workload-identity"
}

variable "replicas" {
  type    = number
  default = 2
}
