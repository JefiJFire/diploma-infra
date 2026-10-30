output "state_bucket" {
  value = yandex_storage_bucket.tfstate.bucket
}

output "registry_id" {
  value = yandex_container_registry.this.id
}

output "registry_url" {
  value = "cr.yandex/${yandex_container_registry.this.id}"
}

output "s3_access_key" {
  description = "AWS_ACCESS_KEY_ID для S3-бэкенда"
  value       = yandex_iam_service_account_static_access_key.terraform.access_key
  sensitive   = true
}

output "s3_secret_key" {
  description = "AWS_SECRET_ACCESS_KEY для S3-бэкенда"
  value       = yandex_iam_service_account_static_access_key.terraform.secret_key
  sensitive   = true
}

# JSON-ключ в формате, который понимает провайдер yandex и `yc config`
output "terraform_sa_key_json" {
  value = jsonencode({
    id                 = yandex_iam_service_account_key.terraform.id
    service_account_id = yandex_iam_service_account.terraform.id
    created_at         = yandex_iam_service_account_key.terraform.created_at
    key_algorithm      = yandex_iam_service_account_key.terraform.key_algorithm
    public_key         = yandex_iam_service_account_key.terraform.public_key
    private_key        = yandex_iam_service_account_key.terraform.private_key
  })
  sensitive = true
}

output "ci_sa_key_json" {
  description = "Ключ для входа в реестр из CI: docker login -u json_key --password-stdin cr.yandex"
  value = jsonencode({
    id                 = yandex_iam_service_account_key.ci.id
    service_account_id = yandex_iam_service_account.ci.id
    created_at         = yandex_iam_service_account_key.ci.created_at
    key_algorithm      = yandex_iam_service_account_key.ci.key_algorithm
    public_key         = yandex_iam_service_account_key.ci.public_key
    private_key        = yandex_iam_service_account_key.ci.private_key
  })
  sensitive = true
}
