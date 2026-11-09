# Переменные для провайдера Yandex Cloud
variable "token" {
  description = "OAuth-токен или IAM-токен Yandex Cloud (либо service_account_key_file). Чувствительно."
  type        = string
  sensitive   = true
  default     = null
}

variable "service_account_key_file" {
  description = "Путь к JSON-ключу сервисного аккаунта (альтернатива token)."
  type        = string
  default     = null
}

variable "cloud_id" {
  description = "ID облака Yandex Cloud."
  type        = string
}

variable "folder_id" {
  description = "ID каталога, в котором создаётся инфраструктура."
  type        = string
}

variable "default_zone" {
  description = "Зона по умолчанию для провайдера."
  type        = string
  default     = "ru-central1-a"
}

# Сетевые параметры
variable "network_name" {
  description = "Имя облачной сети."
  type        = string
  default     = "future20-network"
}

variable "zone_a" {
  description = "Первая зона доступности (публичная подсеть + app-1)."
  type        = string
  default     = "ru-central1-a"
}

variable "zone_b" {
  description = "Вторая зона доступности (app-2) для отказоустойчивости."
  type        = string
  default     = "ru-central1-b"
}

variable "public_subnet_cidr" {
  description = "CIDR публичной подсети (зона A): bastion."
  type        = string
  default     = "10.10.0.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR приватной подсети (зона A): сервисные ВМ, egress через NAT."
  type        = string
  default     = "10.10.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR приватной подсети (зона B): сервисные ВМ, egress через NAT."
  type        = string
  default     = "10.10.1.0/24"
}

variable "admin_cidr" {
  description = "CIDR администраторов, откуда разрешён SSH к bastion. Укажите свой офисный/домашний IP."
  type        = string
  default     = "0.0.0.0/0"
}

# Параметры виртуальных машин
variable "image_family" {
  description = "Семейство образа ОС из Yandex Cloud Marketplace."
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу для доступа к ВМ."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "bastion_vm" {
  description = "Параметры ВМ bastion (edge-узел, публичный IP)."
  type = object({
    name    = string
    vcpus   = number
    memory  = number
    disk_gb = number
  })
  default = {
    name    = "future20-bastion"
    vcpus   = 2
    memory  = 4
    disk_gb = 20
  }
}

variable "app_vm" {
  description = "Параметры сервисных ВМ приложения (в приватных подсетях, 2 зоны)."
  type = object({
    vcpus        = number
    memory       = number
    boot_disk_gb = number
  })
  default = {
    vcpus        = 2
    memory       = 8
    boot_disk_gb = 30
    data_disk_gb = 50
  }
}

variable "app_vm_count" {
  description = "Количество сервисных ВМ (по одной на зону доступности)."
  type        = number
  default     = 2
}

variable "labels" {
  description = "Общие метки для всех ресурсов (учёт и группировка)."
  type        = map(string)
  default = {
    project     = "future20"
    environment = "prod"
    managed-by  = "terraform"
  }
}
