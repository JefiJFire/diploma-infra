terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }

  # Имя бакета и ключи передаются снаружи:
  #   terraform init -backend-config=backend.hcl
  # Ключи доступа: переменные окружения AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region = "ru-central1"
    key    = "infra/terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

# Аутентификация: YC_SERVICE_ACCOUNT_KEY_FILE (путь к JSON-ключу terraform-sa)
provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}
