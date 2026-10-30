# ---------------------------------------------------------------------------
# Сервисный аккаунт для Terraform (основная инфраструктура) с минимальными правами
# ---------------------------------------------------------------------------
resource "yandex_iam_service_account" "terraform" {
  name        = "terraform-sa"
  description = "Сервисный аккаунт Terraform для основной инфраструктуры"
}

locals {
  terraform_roles = [
    "compute.editor", # ВМ, диски, образы
    "vpc.admin",      # сети, подсети, группы безопасности, публичные IP
    "storage.admin", # доступ к бакету с tfstate
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "terraform" {
  for_each = toset(local.terraform_roles)

  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

# Авторизованный ключ (для провайдера yandex) и статический ключ (для S3-бэкенда)
resource "yandex_iam_service_account_key" "terraform" {
  service_account_id = yandex_iam_service_account.terraform.id
}

resource "yandex_iam_service_account_static_access_key" "terraform" {
  service_account_id = yandex_iam_service_account.terraform.id
}

# ---------------------------------------------------------------------------
# Бакет для tfstate
# ---------------------------------------------------------------------------
resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.state_bucket_name
  access_key = yandex_iam_service_account_static_access_key.terraform.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform.secret_key

  versioning {
    enabled = true
  }

  # Роли должны примениться до обращения к S3 API от имени аккаунта
  depends_on = [yandex_resourcemanager_folder_iam_member.terraform]
}

# ---------------------------------------------------------------------------
# Container Registry и сервисный аккаунт для CI (push образов)
# ---------------------------------------------------------------------------
resource "yandex_container_registry" "this" {
  name      = var.registry_name
  folder_id = var.folder_id
}

resource "yandex_iam_service_account" "ci" {
  name        = "ci-registry-sa"
  description = "Сервисный аккаунт CI для публикации образов в реестр"
}

resource "yandex_container_registry_iam_binding" "ci_pusher" {
  registry_id = yandex_container_registry.this.id
  role        = "container-registry.images.pusher"
  members     = ["serviceAccount:${yandex_iam_service_account.ci.id}"]
}

resource "yandex_iam_service_account_key" "ci" {
  service_account_id = yandex_iam_service_account.ci.id
}

# Анонимное скачивание образов, чтобы кластеру не требовался imagePullSecret
resource "yandex_container_registry_iam_binding" "public_pull" {
  count = var.registry_public_pull ? 1 : 0

  registry_id = yandex_container_registry.this.id
  role        = "container-registry.images.puller"
  members     = ["system:allUsers"]
}
