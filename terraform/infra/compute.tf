data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Квоты на HDD (на зону): a = 60 ГБ, d = 30 ГБ.
# Пока зоны не меняются, по размерам дисков это ровно: a = master + monitoring, d = worker1.
# Добавить узел = добавить запись в эту карту (и подсеть зоны в network.tf, если её там нет).
locals {
  nodes = {
    master = {
      role          = "master"
      zone          = "ru-central1-a"
      memory        = var.master_memory
      core_fraction = 20
      disk_size     = 30
      preemptible   = false
      static_ip     = true # адрес API-сервера не должен меняться
      label         = ""
    }

    # Узел под мониторинг: kube-prometheus (Prometheus, Grafana, Alertmanager)
    # размещается на нём через nodeSelector role=monitoring
    monitoring = {
      role          = "worker"
      zone          = "ru-central1-a"
      memory        = var.monitoring_memory
      core_fraction = 20
      disk_size     = 30
      preemptible   = true
      static_ip     = false
      label         = "monitoring"
    }

    # Принимает входящий трафик (ingress на 80): тестовое приложение и Grafana
    worker1 = {
      role          = "worker"
      zone          = "ru-central1-d"
      memory        = var.worker_memory
      core_fraction = 20
      disk_size     = 30
      preemptible   = true
      static_ip     = true
      label         = ""
    }
  }
}

resource "yandex_vpc_address" "node" {
  for_each = { for k, v in local.nodes : k => v if v.static_ip }

  name = "${var.prefix}-${each.key}-ip"

  external_ipv4_address {
    zone_id = each.value.zone
  }
}

resource "yandex_compute_instance" "node" {
  for_each = local.nodes

  name                      = "${var.prefix}-${each.key}"
  hostname                  = each.key
  zone                      = each.value.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = each.value.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this[each.value.zone].id
    nat                = true
    nat_ip_address     = try(yandex_vpc_address.node[each.key].external_ipv4_address[0].address, null)
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(var.ssh_public_key)}"
  }

  # Семейство образов обновляется со временем. Без этого CI при очередном apply
  # пересоздал бы уже работающие ВМ (и кластер на них)
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }
}
