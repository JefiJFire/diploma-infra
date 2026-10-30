locals {
  subnets = {
    "ru-central1-a" = "10.10.1.0/24"
    "ru-central1-d" = "10.10.3.0/24"
  }
}

resource "yandex_vpc_network" "this" {
  name = "${var.prefix}-net"
}

resource "yandex_vpc_subnet" "this" {
  for_each = local.subnets

  name           = "${var.prefix}-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value]
}

resource "yandex_vpc_security_group" "k8s" {
  name       = "${var.prefix}-k8s"
  network_id = yandex_vpc_network.this.id

  # Весь трафик между узлами кластера
  ingress {
    description       = "node-to-node"
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }

  dynamic "ingress" {
    for_each = var.admin_cidrs
    content {
      description    = "ssh"
      protocol       = "TCP"
      port           = 22
      v4_cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.api_cidrs
    content {
      description    = "kubernetes api"
      protocol       = "TCP"
      port           = 6443
      v4_cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description    = "http"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "https"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "any outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
