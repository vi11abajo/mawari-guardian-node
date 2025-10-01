#!/bin/bash

# Скрипт остановки Mawari Guardian Node

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Остановка Mawari Guardian Node...${NC}"

docker-compose down

echo -e "${RED}Нода остановлена!${NC}"
