# diploma-infra

Terraform-конфигурации для дипломного проекта (Yandex Cloud) и точка входа для Ansible/Kubespray.

## Структура репозиториев

| Репозиторий | Содержимое |
|---|---|
| `diploma-infra` (этот) | `terraform/bootstrap`, `terraform/infra`, `ansible/`, workflow Terraform |
| `diploma-k8s` | манифесты и values: kube-prometheus, ingress-nginx, Grafana, приложение |
| `diploma-app` | nginx-конфиг, статика, Dockerfile, workflow сборки и деплоя |

```
diploma-infra/
├── terraform/
│   ├── bootstrap/   # сервисный аккаунт, бакет tfstate, реестр образов (локальный state, не удаляется)
│   └── infra/       # VPC, подсети, SG, 3 ВМ (state в бакете, можно destroy/apply)
├── ansible/
│   ├── Makefile     # setup, ping, k8s-up, kubeconfig, check
│   └── inventory/   # hosts.yaml создаёт Terraform; group_vars для Kubespray
└── .github/workflows/terraform.yml
```

## Порядок работы

### 1. Bootstrap (один раз)

```bash
export YC_TOKEN=$(yc iam create-token)
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # Заполнить cloud_id, folder_id, имя бакета
terraform init && terraform apply
```

Данные для основной конфигурации и GitHub secrets:

```bash
terraform output -raw terraform_sa_key_json > ~/.config/yc/terraform-sa-key.json   # YC_SA_KEY_JSON
terraform output -raw s3_access_key   # S3_ACCESS_KEY
terraform output -raw s3_secret_key   # S3_SECRET_KEY
terraform output -raw ci_sa_key_json  # ключ для docker login в diploma-app
terraform output -raw registry_id
```

### 2. Основная инфраструктура

```bash
export YC_SERVICE_ACCOUNT_KEY_FILE=~/.config/yc/terraform-sa-key.json
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=... # S3_ACCESS_KEY и S3_SECRET_KEY из прошлого этапа
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_yc.pub)"
cd terraform/infra
cp terraform.tfvars.example terraform.tfvars  # Заполнить cloud_id, folder_id
cp backend.hcl.example backend.hcl            # Заполнить имя бакета как из прошлого этапа
terraform init -backend-config=backend.hcl
terraform apply
```

При `apply` Terraform сам записывает `ansible/inventory/hosts.yaml` с актуальными адресами узлов.

### 3. Kubernetes (Kubespray)

Нужны локально: `git`, `python3` с `venv`, `kubectl`, SSH-ключ, чей публичный ключ передан в `TF_VAR_ssh_public_key`.

```bash
cd ansible
make up                      # setup + ping + k8s-up + kubeconfig + check
# или по шагам:
make setup                   # Kubespray v2.32.0 и Ansible в .venv
make ping                    # SSH-доступ к узлам
make k8s-up                  # установка кластера (20-30 минут)
make kubeconfig              # добавляет кластер в ~/.kube/config (с резервной копией)
make check                   # kubectl get nodes / pods
```

### 4. GitHub Secrets для workflow

`YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_SA_KEY_JSON`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `STATE_BUCKET`, `SSH_PUBLIC_KEY`.

Workflow на PR пишет `terraform plan` комментарием, на push в `main` выполняет `apply` (вариант «CI/CD-terraform» из задания).

## 5. CI/CD (GitHub Actions)

`.github/workflows/terraform.yml`: pull request запускает fmt, validate, plan и публикует план комментарием;
коммит в `main` запускает apply. Секреты репозитория: `YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_SA_KEY_JSON`
(ключ terraform-sa), `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `STATE_BUCKET`, `SSH_PUBLIC_KEY`.
Значения берутся из `terraform output` каталога `terraform/bootstrap`.

## Ресурсы

Квоты облака на HDD: 60 ГБ в зоне a, 30 ГБ в зоне d, 20 ГБ в зоне e (неиспользовал в проекте). Зона b недоступна. Размеры дисков заданы в `locals.nodes` (`terraform/infra/compute.tf`).

| ВМ | Зона | Параметры | Тип | Публичный IP | Назначение |
|---|---|---|---|---|---|
| master | ru-central1-a | 2 vCPU 20%, 4 ГБ, HDD 30 ГБ | обычная | статический | control plane, etcd |
| monitoring | ru-central1-a | 2 vCPU 20%, 6 ГБ, HDD 30 ГБ | прерываемая | динамический | kube-prometheus (метка `role=monitoring`) |
| worker1 | ru-central1-d | 2 vCPU 20%, 4 ГБ, HDD 30 ГБ | прерываемая | статический | ingress, тестовое приложение |

Все узлы получают публичный IP, чтобы не платить за NAT-шлюз. Network Load Balancer не используется.

Для экономии ресурсовм, ВМ diploma-monitoring и diploma-worker1 сделаны прерываемыми (останавливаются через 24 часа работы). Перезапустить из консоли можно командой:  
`yc compute instance start diploma-monitoring diploma-worker1`. После запуска узлы возвращаются в кластер сами.