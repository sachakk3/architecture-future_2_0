# =============================================================================
# «Будущее 2.0» — облачная инфраструктура в Yandex Cloud (IaaS + Terraform)
#
# ВАЖНО (ограничения учебной песочницы Практикума):
#   В песочнице папки запрещено создание NAT Gateway, Security Groups
#   и отдельных ресурсов yandex_compute_disk. Поэтому в проверяемой
#   конфигурации сервисные ВМ получают публичные IP (nat = true),
#   диски данных входят в состав boot-дисков, а изоляция достигается
#   выбором подсетей. Производственный вариант (NAT Gateway + SG +
#   отдельные диски) описан в diagram.png и justification.md.
# =============================================================================

terraform {
  required_version = ">= 1.8"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140"
    }
  }
}

provider "yandex" {
  token                    = var.token
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}

# -----------------------------------------------------------------------------
# Образ ОС из Marketplace (family → актуальная версия образа)
# -----------------------------------------------------------------------------
data "yandex_compute_image" "os" {
  family = var.image_family
}

# -----------------------------------------------------------------------------
# Сеть: VPC и подсети в двух зонах доступности
# -----------------------------------------------------------------------------
resource "yandex_vpc_network" "main" {
  name        = var.network_name
  description = "Сеть «Будущее 2.0»: публичная подсеть bastion и подсети сервисов"
  labels      = var.labels
}

resource "yandex_vpc_subnet" "public" {
  name           = "${var.network_name}-public-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr]
  labels         = var.labels
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "${var.network_name}-private-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr_a]
  labels         = var.labels
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "${var.network_name}-private-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  labels         = var.labels
}

# -----------------------------------------------------------------------------
# Bastion: публичный IP, небольшая конфигурация (точка входа SSH)
# -----------------------------------------------------------------------------
resource "yandex_compute_instance" "bastion" {
  name     = var.bastion_vm.name
  hostname = var.bastion_vm.name
  zone     = var.zone_a
  labels   = var.labels

  resources {
    cores         = var.bastion_vm.vcpus
    memory        = var.bastion_vm.memory
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      size     = var.bastion_vm.disk_gb
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key_path))}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# -----------------------------------------------------------------------------
# Сервисные ВМ приложения.
# В песочнице используются публичные IP (nat = true), т.к. NAT Gateway
# в учебной папке запрещён; в проде — приватные подсети + NAT Gateway.
# В учебном облаке доступна только зона ru-central1-a (zone B недоступна),
# поэтому обе ВМ размещены в зоне A; в проде они распределяются по
# zone_a/zone_b для отказоустойчивости (см. diagram.png).
# -----------------------------------------------------------------------------
resource "yandex_compute_instance" "app" {
  count = var.app_vm_count

  name     = "${var.network_name}-app-${count.index + 1}"
  hostname = "${var.network_name}-app-${count.index + 1}"
  zone     = var.zone_a
  labels   = var.labels

  resources {
    cores         = var.app_vm.vcpus
    memory        = var.app_vm.memory
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      size     = var.app_vm.boot_disk_gb
      # В песочнице крошечные дисковые квоты: SSD ~10 GB, HDD ~20 GB на папку.
      # app-1 использует network-ssd, app-2 — network-hdd (умещаемся в квоту).
      # В проде все boot-диски — network-ssd 30 GB + отдельный data-диск 50 GB.
      type = count.index == 0 ? "network-ssd" : "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_a.id
    nat       = true
  }

  # Изменение размеров ВМ через Terraform останавливает инстанс
  allow_stopping_for_update = true

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key_path))}"
  }

  scheduling_policy {
    preemptible = false
  }
}
