# Значения переменных для развёртывания «Будущее 2.0»
# ВАЖНО: замените плейсхолдеры на реальные значения вашего облака.

cloud_id  = "b1gxxxxxxxxxxxxxxxxx" # TODO: ID облака (yc cloud list)
folder_id = "b1gyyyyyyyyyyyyyyyyy" # TODO: ID каталога (yc folder list)

# Учётные данные: указывается ЛИБО token, ЛИБО путь к ключу сервисного аккаунта.
# Не коммитьте реальные токены в репозиторий!
# token                     = "<OAuth/IAM token>"
# service_account_key_file  = "/secure/path/service-account-key.json"

default_zone = "ru-central1-a"
zone_a       = "ru-central1-a"
zone_b       = "ru-central1-b"

network_name          = "future20-network"
public_subnet_cidr    = "10.10.0.0/24"
private_subnet_cidr_a = "10.10.2.0/24"
private_subnet_cidr   = "10.10.1.0/24"

# Диапазон, с которого разрешён SSH к bastion:
# замените на офисный/домашний IP (например, "203.0.113.5/32")
admin_cidr = "0.0.0.0/0"

image_family        = "ubuntu-2204-lts"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

bastion_vm = {
  name   = "future20-bastion"
  vcpus  = 2
  memory = 4
  # 10 GB — ужимаемся в дисковую квоту учебной песочницы (~20 GB HDD на папку)
  disk_gb = 10
}

app_vm = {
  vcpus = 2
  # 4 GB — максимум, допустимый квотой памяти зоны учебной песочницы
  # (bastion 4 GB + 2 app-ВМ). В проде: 8 GB.
  memory = 4
  # Максимальные размеры, допустимые квотами учебной песочницы.
  # В проде: boot 30 GB network-ssd + отдельный диск данных 50 GB network-ssd.
  boot_disk_gb = 8
}

app_vm_count = 2

labels = {
  project     = "future20"
  environment = "prod"
  managed-by  = "terraform"
}
