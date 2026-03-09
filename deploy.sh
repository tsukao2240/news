#!/bin/bash
set -e

source "$(dirname "$0")/.env.production"

echo "Syncing files..."
rsync -av --exclude='.git' /home/tsukao/project/news oracle-news:~/

echo "Deploying..."
ssh oracle-news "cd ~/news && docker compose --env-file .env.production down && docker compose --env-file .env.production up -d"

echo "Updating workflows via API..."
ssh oracle-news "for i in \$(seq 1 20); do curl -sf http://localhost:5678/healthz > /dev/null 2>&1 && break; echo \"  [\$i/20] waiting...\"; sleep 3; done"

for f in /home/tsukao/project/news/workflows/*.json; do
  id=$(python3 -c "import json; print(json.load(open('$f'))['id'])")
  name=$(python3 -c "import json; print(json.load(open('$f'))['name'])")
  echo "  Updating: $name ($id)"
  ssh oracle-news "curl -sf -X PUT http://localhost:5678/api/v1/workflows/$id \
    -H 'X-N8N-API-KEY: ${N8N_API_KEY}' \
    -H 'Content-Type: application/json' \
    -d @~/news/workflows/$(basename $f)"
done

echo "Done!"
