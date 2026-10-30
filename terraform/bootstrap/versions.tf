terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
  }
}

# Аутентификация bootstrap-конфигурации выполняется от имени владельца облака:
#   export YC_TOKEN=$(yc iam create-token)
provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
