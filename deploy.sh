#!/usr/bin/env bash
# Deploy a fresh Twenty CRM (server, worker, Postgres, Redis, file bucket) as a new Railway project.
# Usage: ./deploy.sh "<project name>" [workspace id or name]
set -euo pipefail

NAME=${1:?usage: ./deploy.sh "<project name>" [workspace]}
WORKSPACE=${2:-}
TEMPLATE_ID=${TWENTY_TEMPLATE_ID:-f53254f7-ce8d-426e-844e-6ece5f030405}
HERE=$(cd "$(dirname "$0")" && pwd)

command -v railway >/dev/null || { echo "Install the Railway CLI first: https://docs.railway.com/cli" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
railway whoami >/dev/null || { echo "Run 'railway login' first" >&2; exit 1; }

# railway init links the current directory, so do it in a scratch dir.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
railway init --name "$NAME" ${WORKSPACE:+--workspace "$WORKSPACE"} --json </dev/null > project.json
PROJECT_ID=$(python3 -c "import json;print(json.load(open('project.json'))['id'])")
ENV_ID=$(railway api 'query($p:String!){project(id:$p){environments{edges{node{id name}}}}}' --var p="$PROJECT_ID" </dev/null \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['project']['environments']['edges'][0]['node']['id'])")

# One deploy call creates every service, the bucket and the public domain together,
# so SERVER_URL is set on the very first boot (an empty SERVER_URL breaks first-time setup).
python3 - "$HERE/twenty.template.json" "$PROJECT_ID" "$ENV_ID" "$TEMPLATE_ID" > vars.json <<'EOF'
import json,sys
cfg,p,e,t=sys.argv[1:]
print(json.dumps({"i":{"projectId":p,"environmentId":e,"templateId":t,"serializedConfig":json.load(open(cfg))}}))
EOF
railway api 'mutation($i:TemplateDeployV2Input!){templateDeployV2(input:$i){projectId workflowId}}' --variables @vars.json </dev/null >/dev/null

echo "Project created: https://railway.com/project/$PROJECT_ID"
echo "Waiting for the public URL..."
for _ in $(seq 1 60); do
  DOMAIN=$(railway api 'query($p:String!){project(id:$p){services{edges{node{name serviceInstances{edges{node{domains{serviceDomains{domain}}}}}}}}}}' --var p="$PROJECT_ID" </dev/null \
    | python3 -c "
import sys,json
for s in json.load(sys.stdin)['data']['project']['services']['edges']:
  if s['node']['name']=='twenty':
    for i in s['node']['serviceInstances']['edges']:
      for d in i['node']['domains']['serviceDomains']: print(d['domain'])" | head -1)
  [ -n "$DOMAIN" ] && break; sleep 5
done
[ -n "${DOMAIN:-}" ] || { echo "No domain yet, check the Railway dashboard" >&2; exit 1; }

URL="https://$DOMAIN"
echo "Waiting for $URL (first boot sets up the database, about 5 minutes)..."
for _ in $(seq 1 90); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/")" = 200 ] && { echo "Twenty is up: $URL"; echo "The first person to sign up becomes the admin."; exit 0; }
  sleep 10
done
echo "Not up after 15 minutes. Check logs: railway logs --service twenty (after railway link $PROJECT_ID)" >&2
exit 1
