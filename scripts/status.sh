#!/bin/bash

# Скрипт проверки статуса Mawari Guardian Node

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Статус Mawari Guardian Node${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Проверка статуса контейнера
if [ "$(docker ps -q -f name=mawari-guardian-node)" ]; then
    echo -e "${GREEN}✓ Нода запущена${NC}"
    echo ""

    # Информация о контейнере
    echo "Информация о контейнере:"
    docker ps -f name=mawari-guardian-node --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    # Использование ресурсов
    echo "Использование ресурсов:"
    docker stats --no-stream mawari-guardian-node
    echo ""

    # Последние 10 строк логов
    echo "Последние логи:"
    docker-compose logs --tail=10
else
    echo -e "${RED}✗ Нода не запущена${NC}"
    echo ""
    echo "Запустите ноду командой: ./scripts/start.sh"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
