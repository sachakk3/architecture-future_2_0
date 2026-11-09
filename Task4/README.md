# Задание 4 — «Будущее 2.0»: облачная инфраструктура (IaaS + Terraform)

## Состав решения

| Файл                                                 | Содержание                                                                                                  |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| [`main.tf`](main.tf)                                 | Описание инфраструктуры: VPC, 3 подсети, bastion, 2 сервисные ВМ                                            |
| [`variables.tf`](variables.tf)                       | Переменные: провайдер, CIDR-план, размеры ВМ, метки                                                         |
| [`outputs.tf`](outputs.tf)                           | Ключевые параметры: IP-адреса, ID сетей/подсетей                                                            |
| [`terraform.tfvars`](terraform.tfvars)               | Значения переменных (IDs облака/папки не коммитятся — см. credentials.auto.tfvars)                          |
| [`credentials.auto.tfvars`](credentials.auto.tfvars) | ID облака/каталога (в git не попадает: `*.auto.tfvars` в .gitignore)                                        |
| [`diagram.png`](diagram.png)                         | Диаграмма автоматизации развёртывания (исходник [`deployment-automation.puml`](deployment-automation.puml)) |
| [`apply-result.png`](apply-result.png)               | Скриншот результата `terraform apply` для пул-реквеста                                                      |
| [`justification.md`](justification.md)               | Обоснование выбора ресурсов, параметров и IaC-подхода                                                       |

## Что создаётся Terraform (проверено apply)

- VPC-сеть `future20-network`;
- публичная подсеть `10.10.0.0/24` (зона A) и две приватные `10.10.2.0/24`, `10.10.1.0/24`;
- **bastion** — 2 vCPU/4 GB, 10 GB HDD, публичный IP, SSH-ключ через metadata;
- **app-1 / app-2** — 2 vCPU/4 GB, 8 GB SSD/HDD, публичные IP (в проде — приватные + NAT Gateway, см. diagram.png).

Разворачивается вручную (bootstrap): сервисный аккаунт/OAuth-токен, бакет для remote state, DNS-записи, SSH-ключи инженеров — всё это отмечено на диаграмме оранжевым.

## Как воспроизвести

```bash
cd Task4
terraform init                                   # провайдер с зеркала YC
export YC_TOKEN=$(~/yandex-cloud/bin/yc iam create-token)
terraform plan
terraform apply
terraform output bastion_public_ip               # точка входа SSH
```

## Проверка выполнена

- `terraform validate` — Success!
- `terraform plan` — 12+ ресурсов к созданию
- `terraform apply` — **Apply complete!** (см. [`apply-result.png`](apply-result.png)); ВМ bastion и 2 app-инстанса запущены в Yandex Cloud.

## Ограничения учебной песочницы (зафиксированы и обойдены)

| Ограничение песочницы                          | Решение в проверяемой конфигурации | Прод-вариант (diagram.png)  |
| ---------------------------------------------- | ---------------------------------- | --------------------------- |
| NAT Gateway запрещён                           | `nat = true` на ВМ                 | NAT Gateway + Route Table   |
| Security Groups запрещены                      | сегментация подсетей               | SG: SSH только от bastion   |
| Отдельные диски запрещены                      | boot-диски 8–10 GB                 | отдельные 50 GB network-ssd |
| Зона ru-central1-b недоступна для ВМ           | обе app-ВМ в зоне A                | app-ВМ по двум зонам        |
| Квоты: ~10 GB SSD, ~10 GB HDD, ~16 GB RAM/зону | уменьшенные размеры                | 30 GB SSD boot + 50 GB data |

Подробное обоснование — в [`justification.md`](justification.md).
