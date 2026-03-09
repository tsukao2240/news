#!/bin/bash
set -e

source "$(dirname "$0")/.env.production"

echo "Syncing files..."
rsync -av --exclude='.git' /home/tsukao/project/news oracle-news:~/

echo "Deploying..."
ssh oracle-news "cd ~/news && docker compose --env-file .env.production down && docker compose --env-file .env.production up -d"

echo "Waiting for n8n to start..."
ssh oracle-news "for i in \$(seq 1 20); do curl -sf -H 'X-N8N-API-KEY: ${N8N_API_KEY}' http://localhost:5678/api/v1/workflows > /dev/null 2>&1 && echo 'n8n API ready' && break; echo \"  [\$i/20] waiting...\"; sleep 3; done"

echo "Updating workflows via API..."
for f in /home/tsukao/project/news/workflows/*.json; do
  id=$(python3 -c "import json; print(json.load(open('$f'))['id'])")
  name=$(python3 -c "import json; print(json.load(open('$f'))['name'])")
  echo "  Updating: $name ($id)"

  result=$(ssh oracle-news "python3 -c \"
import json
d = json.load(open('/home/ubuntu/news/workflows/$(basename $f)'))
body = {k: d[k] for k in ['name','nodes','connections'] if k in d}
if 'settings' in d:
    body['settings'] = {k: d['settings'][k] for k in ['executionOrder','timezone'] if k in d['settings']}
print(json.dumps(body))
\" | curl -s -o /tmp/n8n_resp.json -w '%{http_code}' -X PUT http://localhost:5678/api/v1/workflows/$id \
    -H 'X-N8N-API-KEY: ${N8N_API_KEY}' \
    -H 'Content-Type: application/json' \
    -d @- && cat /tmp/n8n_resp.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\"OK\")' 2>/dev/null || cat /tmp/n8n_resp.json")

  if echo "$result" | grep -q "^200"; then
    echo "    -> Updated successfully"
  else
    echo "    -> ERROR: $result"
    exit 1
  fi

  ssh oracle-news "curl -sf -X PATCH http://localhost:5678/api/v1/workflows/$id/activate \
    -H 'X-N8N-API-KEY: ${N8N_API_KEY}'" && echo "    -> Activated"
done

echo "Done!"
