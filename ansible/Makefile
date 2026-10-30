# Версия Kubespray и путь к SSH-ключу можно переопределить:
#   make k8s-up KUBESPRAY_VERSION=v2.32.0 SSH_KEY=~/.ssh/id_rsa
KUBESPRAY_VERSION ?= v2.32.0
SSH_KEY           ?= $(HOME)/.ssh/id_yc

VENV        := $(CURDIR)/.venv
INVENTORY   := $(CURDIR)/inventory/hosts.yaml
ADMIN_CONF  := $(CURDIR)/inventory/artifacts/admin.conf
CONTEXT     := kubernetes-admin-cluster.local@cluster.local

export ANSIBLE_HOST_KEY_CHECKING := False

.PHONY: help setup inventory ping k8s-up kubeconfig check up

help:
	@echo "make setup       - скачать Kubespray $(KUBESPRAY_VERSION) и установить Ansible в .venv"
	@echo "make inventory   - пересоздать inventory из terraform output"
	@echo "make ping        - проверить SSH-доступ ко всем узлам"
	@echo "make k8s-up      - развернуть кластер (Kubespray)"
	@echo "make kubeconfig  - добавить доступ к кластеру в ~/.kube/config"
	@echo "make check       - kubectl get nodes / pods"
	@echo "make up          - setup + ping + k8s-up + kubeconfig + check"

# --- подготовка ---------------------------------------------------------

kubespray/cluster.yml:
	GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 --branch $(KUBESPRAY_VERSION) \
		https://github.com/kubernetes-sigs/kubespray kubespray

$(VENV)/.installed: kubespray/cluster.yml
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r kubespray/requirements.txt
	touch $@

setup: $(VENV)/.installed

# Inventory обычно создаёт сам Terraform (ресурс local_file) при apply.
# Эта цель нужна, если файл удалили или нужно пересоздать вручную.
inventory:
	cd ../terraform/infra && terraform output -raw ansible_inventory > $(INVENTORY)

# --- кластер ------------------------------------------------------------

ping: setup
	@test -f $(INVENTORY) || { echo "Нет $(INVENTORY): выполните terraform apply или make inventory"; exit 1; }
	$(VENV)/bin/ansible -i $(INVENTORY) all -m ping --private-key $(SSH_KEY)

k8s-up: setup
	@test -f $(INVENTORY) || { echo "Нет $(INVENTORY): выполните terraform apply или make inventory"; exit 1; }
	cd kubespray && $(VENV)/bin/ansible-playbook -i $(INVENTORY) \
		--private-key $(SSH_KEY) --become cluster.yml

# Склеивает доступ к кластеру с текущим ~/.kube/config (с резервной копией).
# admin.conf стоит первым, поэтому при пересоздании кластера
# старые записи с тем же именем заменяются новыми.
kubeconfig:
	@test -f $(ADMIN_CONF) || { echo "Нет $(ADMIN_CONF): сначала make k8s-up"; exit 1; }
	@mkdir -p $(HOME)/.kube
	@if [ -f $(HOME)/.kube/config ]; then cp $(HOME)/.kube/config $(HOME)/.kube/config.bak.$$(date +%s); fi
	KUBECONFIG=$(ADMIN_CONF):$(HOME)/.kube/config kubectl config view --flatten > $(HOME)/.kube/config.new
	mv $(HOME)/.kube/config.new $(HOME)/.kube/config
	chmod 600 $(HOME)/.kube/config
	kubectl config use-context $(CONTEXT)

check:
	kubectl get nodes -o wide
	kubectl get pods --all-namespaces

up: setup ping k8s-up kubeconfig check
