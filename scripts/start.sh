#!/bin/bash

# Скрипт запуска Mawari Guardian Node

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Запуск Mawari Guardian Node...${NC}"

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    echo "Ошибка: .env файл не найден!"
    echo "Создайте .env файл на основе .env.example"
    exit 1
fi

# Запуск контейнера
docker-compose up -d

echo -e "${GREEN}Нода запущена!${NC}"
echo "Используйте ./scripts/logs.sh для просмотра логов"
echo "Используйте ./scripts/status.sh для проверки статуса"
