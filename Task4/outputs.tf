# Ключевые параметры развёрнутой инфраструктуры

output "network_id" {
  description = "ID облачной сети."
  value       = yandex_vpc_network.main.id
}

output "public_subnet_id" {
  description = "ID публичной подсети (зона A)."
  value       = yandex_vpc_subnet.public.id
}

output "private_subnet_ids" {
  description = "ID приватных подсетей (A и B)."
  value = {
    a = yandex_vpc_subnet.private_a.id
    b = yandex_vpc_subnet.private_b.id
  }
}

output "bastion_public_ip" {
  description = "Публичный IP bastion — точка входа SSH для администраторов."
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "bastion_internal_ip" {
  description = "Внутренний IP bastion в публичной подсети."
  value       = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "app_public_ips" {
  description = "Публичные IP сервисных ВМ (в песочнице; в проде — приватные + NAT Gateway)."
  value       = [for vm in yandex_compute_instance.app : vm.network_interface[0].nat_ip_address]
}

output "app_internal_ips" {
  description = "Внутренние IP сервисных ВМ."
  value       = [for vm in yandex_compute_instance.app : vm.network_interface[0].ip_address]
}

output "app_zones" {
  description = "Зоны доступности сервисных ВМ."
  value       = [for vm in yandex_compute_instance.app : vm.zone]
}
