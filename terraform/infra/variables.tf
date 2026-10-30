variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "prefix" {
  description = "Префикс имён ресурсов"
  type        = string
  default     = "diploma"
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа (например, TF_VAR_ssh_public_key=\"$(cat ~/.ssh/id_ed25519.pub)\")"
  type        = string
}

variable "admin_cidrs" {
  description = "Откуда разрешён SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_cidrs" {
  description = "Откуда разрешён доступ к Kubernetes API (6443). Для GitHub Actions нужен 0.0.0.0/0"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "master_memory" {
  description = "ОЗУ мастера, ГБ"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "ОЗУ рабочего узла (ingress и приложение), ГБ"
  type        = number
  default     = 4
}

variable "monitoring_memory" {
  description = "ОЗУ узла мониторинга, ГБ (kube-prometheus: Prometheus, Grafana, Alertmanager)"
  type        = number
  default     = 6
}

# Проверка CI