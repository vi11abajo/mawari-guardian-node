#!/bin/bash

# Скрипт просмотра логов Mawari Guardian Node

YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Логи Mawari Guardian Node (Ctrl+C для выхода):${NC}"
echo ""

docker-compose logs -f --tail=100
