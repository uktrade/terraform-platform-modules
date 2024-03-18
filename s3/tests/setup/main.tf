terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_pet" "bucket_prefix" {
  length = 2
}

resource "random_pet" "alias_prefix" {
  length = 1
}

output "bucket_prefix" {
  value = random_pet.bucket_prefix.id
}

output "alias_prefix" {
  value = random_pet.alias_prefix.id
}