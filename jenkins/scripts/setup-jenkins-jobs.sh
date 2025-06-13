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
required_vars=("JENKINS_URL" "JENKINS_USER" "JENKINS_TOKEN" "GITHUB_REPO")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "\033[0;31m❌ Error: La variable $var no está definida en secrets.env\033[0m"
        exit 1
    fi
done

# Configuración con valores por defecto si no están en secrets.env
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
GITHUB_REPO="${GITHUB_REPO:-https://github.com/ecommerce-devops-lab/ecommerce-microservice-backend-app.git}"

# Microservicios y sus configuraciones (AMPLIADO)
declare -A services=(
    ["order-service"]="8300"
    ["payment-service"]="8400"
    ["product-service"]="8500"
    ["shipping-service"]="8600"
    ["user-service"]="8700"
    ["api-gateway"]="8080"
    ["service-discovery"]="8761"
    ["cloud-config"]="8888"
)

# Environments (por ahora solo dev)
environments=("dev")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Configurando Jenkins Jobs para desarrollo...${NC}"

# Función para crear job
create_jenkins_job() {
    local service=$1
    local environment=$2
    local port=$3
    local job_name="${service}-${environment}"

    local default_branch="develop"  # Solo dev por ahora
    
    echo -e "${YELLOW}📦 Creando job: ${job_name}${NC}"
    
    # Generar XML del job basado en template
    cat > "/tmp/${job_name}.xml" << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Development pipeline for ${service} microservice</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>BRANCH_NAME</name>
          <description>Branch to build</description>
          <defaultValue>${default_branch}</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>COMMIT_SHA</name>
          <description>Commit SHA</description>
          <defaultValue>HEAD</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_SONAR</name>
          <description>Skip SonarQube analysis</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_SECURITY_SCAN</name>
          <description>Skip Trivy security scan</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${GITHUB_REPO}</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>\${BRANCH_NAME}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>${service}/Jenkinsfile-${environment}</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    # Crear el job en Jenkins
    local response=$(curl -s -w "%{http_code}" \
        -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        -H "Content-Type: application/xml" \
        -X POST \
        "${JENKINS_URL}/createItem?name=${job_name}" \
        --data-binary "@/tmp/${job_name}.xml" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}✅ Job ${job_name} creado exitosamente${NC}"
        return 0
    elif [[ "$http_code" == "400" ]]; then
        echo -e "${YELLOW}⚠️  Job ${job_name} ya existe, actualizando...${NC}"
        
        # Actualizar job existente
        local update_response=$(curl -s -w "%{http_code}" \
            -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
            -H "Content-Type: application/xml" \
            -X POST \
            "${JENKINS_URL}/job/${job_name}/config.xml" \
            --data-binary "@/tmp/${job_name}.xml" 2>/dev/null)
        
        local update_code="${update_response: -3}"
        if [[ "$update_code" == "200" ]]; then
            echo -e "${GREEN}✅ Job ${job_name} actualizado${NC}"
            return 0
        else
            echo -e "${RED}❌ Error actualizando job ${job_name}. HTTP Code: ${update_code}${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error creando job ${job_name}. HTTP Code: ${http_code}${NC}"
        echo -e "${RED}   Response: ${response%???}${NC}"
        return 1
    fi
    
    # Limpiar archivo temporal
    rm -f "/tmp/${job_name}.xml"
}

# Verificar conectividad con Jenkins
echo -e "${BLUE}🔍 Verificando conectividad con Jenkins...${NC}"
jenkins_status=$(curl -s -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_TOKEN}" "${JENKINS_URL}/api/json" 2>/dev/null)
jenkins_code="${jenkins_status: -3}"

if [[ "$jenkins_code" != "200" ]]; then
    echo -e "${RED}❌ No se puede conectar a Jenkins en ${JENKINS_URL}${NC}"
    echo -e "${RED}   Verifica URL, usuario y token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Conectividad con Jenkins verificada${NC}"

# Crear jobs para todos los servicios (solo dev por ahora)
created_jobs=0
failed_jobs=0

for service in "${!services[@]}"; do
    port=${services[$service]}
    for environment in "${environments[@]}"; do
        if create_jenkins_job "$service" "$environment" "$port"; then
            ((created_jobs++))
        else
            ((failed_jobs++))
        fi
        sleep 1
    done
done

echo ""
echo -e "${GREEN}🎉 Configuración de Jenkins completada${NC}"
echo -e "${BLUE}📊 Resumen:${NC}"
echo -e "  - Jobs creados/actualizados: ${created_jobs}"
echo -e "  - Jobs fallidos: ${failed_jobs}"
echo ""
echo -e "${BLUE}📋 Jobs configurados:${NC}"

# Listar jobs creados
for service in "${!services[@]}"; do
    for environment in "${environments[@]}"; do
        echo "  ✅ ${service}-${environment} -> ${JENKINS_URL}/job/${service}-${environment}"
    done
done

echo ""
echo -e "${YELLOW}📝 Siguiente paso: Configurar credenciales en Jenkins${NC}"
echo -e "   - gcp-service-account-key"
echo -e "   - sonarqube-token"
echo -e "   - github-credentials"
echo -e "   - github-token"
echo -e "   - slack-webhook-url (opcional)"