variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога, в котором создаются все ресурсы"
  type        = string
}

variable "zone" {
  description = "Зона по умолчанию для провайдера"
  type        = string
  default     = "ru-central1-a"
}

variable "state_bucket_name" {
  description = "Глобально уникальное имя бакета для tfstate"
  type        = string
}

variable "registry_name" {
  description = "Имя Yandex Container Registry"
  type        = string
  default     = "diploma-registry"
}

variable "registry_public_pull" {
  description = "Разрешить анонимное скачивание образов (упрощает деплой, секреты pull не нужны)"
  type        = bool
  default     = true
}
