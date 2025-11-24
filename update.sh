#!/bin/bash

# Config (sesuaikan kalau perlu)
COMPOSE_FILE="docker-compose.prod.yml"
BRANCH="main"  # Ganti dengan branch Git Anda
SERVICE_BUILD="app nginx"  # Service yang perlu rebuild

# Colors untuk log (opsional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "$$ {YELLOW}=== Update Yaumi LPG Laravel Docker === $${NC}"

# 1. Cek & Pull Git (hemat: skip kalau nggak ada perubahan)
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "$$ {YELLOW}Cek perubahan Git... $${NC}"
    if [ $(git rev-list HEAD...origin/$BRANCH --count) -eq 0 ]; then
        echo -e "$$ {GREEN}No new changes in Git. Skip pull. $${NC}"
    else
        echo -e "$$ {YELLOW}Pulling from Git... $${NC}"
        git pull origin $BRANCH
        if [ $? -ne 0 ]; then
            echo -e "$$ {RED}Git pull gagal! Exit. $${NC}"
            exit 1
        fi
        echo -e "$$ {GREEN}Git pull sukses. $${NC}"
    fi
else
    echo -e "$$ {RED}Bukan Git repo! Exit. $${NC}"
    exit 1
fi

# 2. Rebuild kalau ada perubahan code/composer/Dockerfile (hemat: cek file)
if git diff --name-only HEAD~1 | grep -E "(composer|Dockerfile|docker-compose|supervisor|php.ini|nginx.conf)"; then
    echo -e "$$ {YELLOW}Deteksi perubahan config/code. Rebuild... $${NC}"
    docker compose -f $COMPOSE_FILE build --no-cache $SERVICE_BUILD
    if [ $? -ne 0 ]; then
        echo -e "$$ {RED}Build gagal! Exit. $${NC}"
        exit 1
    fi
    echo -e "$$ {GREEN}Rebuild sukses. $${NC}"
else
    echo -e "$$ {GREEN}No config changes. Skip rebuild. $${NC}"
fi

# 3. Up -d (restart service)
echo -e "$$ {YELLOW}Restarting services... $${NC}"
docker compose -f $COMPOSE_FILE up -d
if [ $? -ne 0 ]; then
    echo -e "$$ {RED}Up -d gagal! Exit. $${NC}"
    exit 1
fi
echo -e "$$ {GREEN}Services up. $${NC}"

# 4. Clear cache Laravel (cepat)
echo -e "$$ {YELLOW}Clearing Laravel cache... $${NC}"
docker compose -f $COMPOSE_FILE exec -T app php artisan config:clear || true
docker compose -f $COMPOSE_FILE exec -T app php artisan route:clear || true
docker compose -f $COMPOSE_FILE exec -T app php artisan cache:clear || true
echo -e "$$ {GREEN}Cache cleared. $${NC}"

# 5. Cek status singkat
echo -e "$$ {YELLOW}Status services: $${NC}"
docker compose -f $COMPOSE_FILE ps

# 6. Opsional: Prune kalau mau bersih (komentar kalau nggak)
# echo -e "$$ {YELLOW}Pruning unused... $${NC}"
# docker system prune -f

echo -e "$$ {GREEN}Update selesai! Akses http://<IP-Pi>:8182 $${NC}"