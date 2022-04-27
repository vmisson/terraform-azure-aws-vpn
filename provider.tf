terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.1.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "=4.9.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "aws" {
  region  = "eu-west-1"
  profile = "lab"
}