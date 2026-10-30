locals {
  node_info = {
    for k, v in yandex_compute_instance.node : k => {
      public_ip  = v.network_interface[0].nat_ip_address
      private_ip = v.network_interface[0].ip_address
      role       = local.nodes[k].role
      label      = local.nodes[k].label
    }
  }
}

output "nodes" {
  description = "Публичные и приватные адреса узлов"
  value       = local.node_info
}

output "master_public_ip" {
  value = local.node_info["master"].public_ip
}

output "ingress_public_ip" {
  description = "Адрес, на котором будут доступны Grafana и тестовое приложение (порт 80)"
  value       = local.node_info["worker1"].public_ip
}

# Inventory для Kubespray создаётся автоматически при apply
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory/hosts.yaml"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/hosts.yaml.tpl", {
    nodes     = local.node_info
    master_ip = local.node_info["master"].public_ip
  })
}

# Тот же inventory текстом (на случай ручного создания):
#   terraform output -raw ansible_inventory > ../../ansible/inventory/hosts.yaml
output "ansible_inventory" {
  description = "Inventory для Kubespray"
  value = templatefile("${path.module}/templates/hosts.yaml.tpl", {
    nodes     = local.node_info
    master_ip = local.node_info["master"].public_ip
  })
}
