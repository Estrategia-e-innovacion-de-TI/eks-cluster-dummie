variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-dummy-test"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "eks-dummy-nodes"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}