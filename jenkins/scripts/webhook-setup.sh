#!/bin/bash

# Cargar variables de entorno
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secrets.env" ]; then
    source "${SCRIPT_DIR}/secrets.env"
fi

GITHUB_REPO="${GITHUB_REPO:-ecommerce-devops-lab/ecommerce-microservice-backend-app}"

echo "🔗 Configurando webhooks de GitHub..."

# Configurar webhook principal
curl -X POST \
    -H "Authorization: token ${REDACTED}" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/${GITHUB_REPO}/hooks" \
    -d "{
        \"name\": \"web\",
        \"active\": true,
        \"events\": [\"push\", \"pull_request\", \"release\"],
        \"config\": {
            \"url\": \"${JENKINS_URL}/github-webhook/\",
            \"content_type\": \"json\",
            \"secret\": \"${REDACTED}\",
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