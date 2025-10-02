#!/bin/bash

# Скрипт автоматической установки Mawari Guardian Node на Ubuntu 22.04
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка ОС
check_os() {
    print_message "Проверка операционной системы..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID

        if [[ "$OS" != "Ubuntu" ]]; then
            print_error "Этот скрипт предназначен для Ubuntu. Обнаружена ОС: $OS"
            exit 1
        fi

        print_message "Обнаружена ОС: $OS $VER"
    else
        print_error "Невозможно определить операционную систему"
        exit 1
    fi
}

# Обновление системы
update_system() {
    print_message "Обновление системы..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

# Установка Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_message "Docker уже установлен: $(docker --version)"
        return
    fi

    print_message "Установка Docker..."

    # Установка зависимостей
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Добавление официального GPG ключа Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Настройка репозитория Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Установка Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Добавление пользователя в группу docker
    sudo usermod -aG docker $USER

    print_message "Docker успешно установлен: $(docker --version)"
}

# Установка Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_message "Docker Compose уже установлен: $(docker-compose --version)"
        return
    fi

    print_message "Установка Docker Compose..."
    sudo apt-get install -y docker-compose
    print_message "Docker Compose успешно установлен: $(docker-compose --version)"
}

# Создание директорий
create_directories() {
    print_message "Создание рабочих директорий..."
    mkdir -p ~/mawari-guardian-node
    mkdir -p ~/mawari-guardian-node/data
    cd ~/mawari-guardian-node
}

# Скачивание конфигурационных файлов
download_configs() {
    print_message "Скачивание конфигурационных файлов..."

    # URL вашего GitHub репозитория
    REPO_URL="https://raw.githubusercontent.com/vi11abajo/mawari-guardian-node/main"

    # Скачивание docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        print_warning "docker-compose.yml уже существует, создаём резервную копию..."
        mv docker-compose.yml docker-compose.yml.backup
    fi
    curl -fsSL ${REPO_URL}/docker-compose.yml -o docker-compose.yml

    # Скачивание .env.example
    if [ ! -f ".env" ]; then
        curl -fsSL ${REPO_URL}/.env.example -o .env
        print_message "Создан файл .env из шаблона"
    else
        print_warning ".env файл уже существует, пропускаем..."
    fi

    # Скачивание скриптов управления
    curl -fsSL ${REPO_URL}/scripts/start.sh -o start.sh
    curl -fsSL ${REPO_URL}/scripts/stop.sh -o stop.sh
    curl -fsSL ${REPO_URL}/scripts/logs.sh -o logs.sh
    curl -fsSL ${REPO_URL}/scripts/status.sh -o status.sh

    chmod +x start.sh stop.sh logs.sh status.sh

    print_message "Конфигурационные файлы успешно скачаны"
}

# Настройка переменных окружения
configure_env() {
    print_message "Настройка переменных окружения..."

    echo ""
    echo "=========================================="
    echo "  Настройка Guardian Node"
    echo "=========================================="
    echo ""

    # Проверка переменной окружения или запрос адреса
    if [ -z "$OWNER_ADDRESS" ]; then
        # Если скрипт запущен через curl | bash, интерактивный ввод не работает
        if [ -t 0 ]; then
            # Запрос адреса кошелька владельца (только если stdin это терминал)
            read -p "Введите адрес вашего кошелька (OWNER_ADDRESS): " owner_address
        else
            print_error "Адрес кошелька не указан!"
            echo ""
            print_message "Завершите установку вручную:"
            echo "  cd ~/mawari-guardian-node"
            echo "  nano .env"
            echo "  # Замените 0xYourWalletAddressHere на ваш адрес кошелька"
            echo "  ./start.sh"
            echo ""
            return 0
        fi
    else
        owner_address="$OWNER_ADDRESS"
    fi

    if [ -n "$owner_address" ]; then
        # Обновление .env файла
        sed -i "s/OWNER_ADDRESS=.*/OWNER_ADDRESS=$owner_address/" .env
        print_message "Переменные окружения настроены"
    fi
}

# Создание systemd сервиса
create_systemd_service() {
    print_message "Создание systemd сервиса..."

    sudo tee /etc/systemd/system/mawari-guardian.service > /dev/null <<EOF
[Unit]
Description=Mawari Guardian Node
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$HOME/mawari-guardian-node
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=$USER

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mawari-guardian.service

    print_message "Systemd сервис создан и активирован"
}

# Главная функция
main() {
    echo ""
    echo "=========================================="
    echo "  Установка Mawari Guardian Node"
    echo "=========================================="
    echo ""

    check_os
    update_system
    install_docker
    install_docker_compose
    create_directories
    download_configs
    configure_env
    create_systemd_service

    echo ""
    echo "=========================================="
    echo "  Установка завершена успешно!"
    echo "=========================================="
    echo ""
    print_message "Для завершения установки Docker выполните:"
    echo "  newgrp docker"
    echo ""
    print_message "Для управления нодой используйте:"
    echo "  ./start.sh   - Запустить ноду"
    echo "  ./stop.sh    - Остановить ноду"
    echo "  ./logs.sh    - Посмотреть логи"
    echo "  ./status.sh  - Проверить статус"
    echo ""
    print_warning "ВАЖНО: Не забудьте:"
    print_warning "1. Перевести 1 токен MAWARI на адрес burner кошелька"
    print_warning "2. Делегировать Guardian NFT через Dashboard"
    echo ""
}

# Запуск
main
