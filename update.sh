#!/bin/bash

# Config
COMPOSE_FILE="docker-compose.prod.yml"
BRANCH="main"
SERVICE_BUILD="app nginx"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Update Yaumi LPG Laravel Docker (Optimized) ===${NC}"

# 1. Cek & Pull Git
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}Cek perubahan Git...${NC}"
    if [ $(git rev-list HEAD...origin/$BRANCH --count) -eq 0 ]; then
        echo -e "${GREEN}No new changes in Git. Skip pull.${NC}"
    else
        echo -e "${YELLOW}Pulling from Git...${NC}"
        git pull origin $BRANCH || { echo -e "${RED}Git pull gagal! Exit.${NC}"; exit 1; }
        echo -e "${GREEN}Git pull sukses.${NC}"
    fi
else
    echo -e "${RED}Bukan Git repo! Exit.${NC}"
    exit 1
fi

# 2. Tentukan perlu rebuild atau tidak
if git diff --name-only HEAD~1 | grep -E "(composer|Dockerfile|docker-compose|supervisor|php.ini|nginx.conf)"; then
    echo -e "${YELLOW}Perubahan dependency/config terdeteksi. Rebuild image...${NC}"
    docker compose -f $COMPOSE_FILE build --no-cache $SERVICE_BUILD || { echo -e "${RED}Build gagal! Exit.${NC}"; exit 1; }
    echo -e "${GREEN}Rebuild sukses.${NC}"
else
    echo -e "${GREEN}Tidak ada perubahan dependency/config. Skip rebuild.${NC}"
fi

# 3. Restart service (selalu dilakukan)
echo -e "${YELLOW}Restarting services...${NC}"
docker compose -f $COMPOSE_FILE up -d || { echo -e "${RED}Up -d gagal! Exit.${NC}"; exit 1; }
echo -e "${GREEN}Services up.${NC}"

# 4. Clear cache Laravel
echo -e "${YELLOW}Clearing Laravel cache...${NC}"
docker compose -f $COMPOSE_FILE exec -T app php artisan config:clear || true
docker compose -f $COMPOSE_FILE exec -T app php artisan route:clear || true
docker compose -f $COMPOSE_FILE exec -T app php artisan view:clear || true
docker compose -f $COMPOSE_FILE exec -T app php artisan cache:clear || true
echo -e "${GREEN}Cache cleared.${NC}"

# 5. Status singkat
echo -e "${YELLOW}Status services:${NC}"
docker compose -f $COMPOSE_FILE ps

echo -e "${GREEN}Update selesai! Akses http://<IP-Pi>:8182/autogen${NC}"
