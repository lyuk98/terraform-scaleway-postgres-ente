terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.59"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.2"
    }
  }
}

provider "scaleway" {}

provider "vault" {}
