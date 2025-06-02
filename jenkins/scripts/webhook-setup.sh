#!/bin/bash

# Cargar variables de entorno desde secrets.env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/secrets.env"

# Verificar si el archivo de variables existe
if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
else
    echo -e "\033[0;31m❌ Error: El archivo secrets.env no existe en ${SCRIPT_DIR}\033[0m"
    echo -e "\033[0;33mℹ️  Crea el archivo con las credenciales necesarias\033[0m"
    exit 1
fi

# Validar variables críticas
required_vars=("GITHUB_TOKEN" "GITHUB_REPO" "JENKINS_URL" "WEBHOOK_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "\033[0;31m❌ Error: La variable $var no está definida en secrets.env\033[0m"
        exit 1
    fi
done

# Configuración con valores por defecto
GITHUB_REPO="${GITHUB_REPO:-ecommerce-devops-lab/ecommerce-microservice-backend-app}"
JENKINS_URL="${JENKINS_URL:-}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-}"

echo "🔗 Configurando webhooks de GitHub..."

# Configurar webhook principal (CORREGIDO: usando variables reales)
curl -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/${GITHUB_REPO}/hooks" \
    -d "{
        \"name\": \"web\",
        \"active\": true,
        \"events\": [\"push\", \"pull_request\", \"release\"],
        \"config\": {
            \"url\": \"${JENKINS_URL}/github-webhook/\",
            \"content_type\": \"json\",
            \"secret\": \"${WEBHOOK_SECRET}\",
            \"insecure_ssl\": \"0\"
        }
    }"

echo "✅ Webhook configurado"

# Configurar branch protection rules
for branch in develop staging main; do
    echo "🛡️  Configurando protección para branch: $branch"
    
    curl -X PUT \
        -H "Authorization: token ${REDACTED}" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${GITHUB_REPO}/branches/${branch}/protection" \
        -d "{
            \"required_status_checks\": {
                \"strict\": true,
                \"contexts\": [
                    \"jenkins/dev-order-service\",
                    \"jenkins/dev-payment-service\",
                    \"jenkins/dev-product-service\"
                ]
            },
            \"enforce_admins\": true,
            \"required_pull_request_reviews\": {
                \"required_approving_review_count\": 1,
                \"dismiss_stale_reviews\": true
            },
            \"restrictions\": null
        }"
done

echo "🎉 Configuración de webhooks completada"