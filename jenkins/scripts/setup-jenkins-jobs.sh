#!/bin/bash

# Cargar variables de entorno si existe secrets.env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/secrets.env" ]; then
    source "${SCRIPT_DIR}/secrets.env"
fi

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
GITHUB_REPO="${GITHUB_REPO:-https://github.com/ecommerce-devops-lab/ecommerce-microservice-backend-app.git}"

# Microservicios y sus configuraciones
declare -A services=(
    ["order-service"]="8300"
    ["payment-service"]="8400"
    ["product-service"]="8500"
    ["shipping-service"]="8600"
    ["user-service"]="8700"
)

# Environments
environments=("dev" "stage" "prod")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Configurando Jenkins Jobs automáticamente...${NC}"

# Función para crear job
create_jenkins_job() {
    local service=$1
    local environment=$2
    local port=$3
    local job_name="${service}-${environment}"

    local default_branch="main"
    if [[ "$environment" == "dev" ]]; then
        default_branch="develop"
    elif [[ "$environment" == "stage" ]]; then
        default_branch="staging"
    fi
    
    echo -e "${YELLOW}📦 Creando job: ${job_name}${NC}"
    
    # Generar XML del job basado en template
    cat > "/tmp/${job_name}.xml" << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Pipeline for ${service} in ${environment} environment</description>
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
EOF

    # Agregar parámetros específicos por environment
    if [[ "$environment" == "prod" ]]; then
        cat >> "/tmp/${job_name}.xml" << EOF
        <hudson.model.StringParameterDefinition>
          <name>RELEASE_VERSION</name>
          <description>Release version</description>
          <defaultValue>1.0.0</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.ChoiceParameterDefinition>
          <name>DEPLOYMENT_STRATEGY</name>
          <description>Deployment strategy</description>
          <choices>
            <string>rolling</string>
            <string>blue-green</string>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
EOF
    fi

    if [[ "$environment" == "stage" ]]; then
        cat >> "/tmp/${job_name}.xml" << EOF
        <hudson.model.BooleanParameterDefinition>
          <name>RUN_E2E_TESTS</name>
          <description>Run E2E tests</description>
          <defaultValue>true</defaultValue>
        </hudson.model.BooleanParameterDefinition>
EOF
    fi

    cat >> "/tmp/${job_name}.xml" << EOF
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
    <scriptPath>jenkins/Jenkinsfile-${environment}</scriptPath>
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
        --data-binary "@/tmp/${job_name}.xml")
    
    local http_code="${response: -3}"
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}✅ Job ${job_name} creado exitosamente${NC}"
    elif [[ "$http_code" == "400" ]]; then
        echo -e "${YELLOW}⚠️  Job ${job_name} ya existe, actualizando...${NC}"
        
        # Actualizar job existente
        curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
            -H "Content-Type: application/xml" \
            -X POST \
            "${JENKINS_URL}/job/${job_name}/config.xml" \
            --data-binary "@/tmp/${job_name}.xml"
        
        echo -e "${GREEN}✅ Job ${job_name} actualizado${NC}"
    else
        echo -e "${RED}❌ Error creando job ${job_name}. HTTP Code: ${http_code}${NC}"
    fi
    
    # Limpiar archivo temporal
    rm -f "/tmp/${job_name}.xml"
}

# Crear jobs para todos los servicios y environments
for service in "${!services[@]}"; do
    port=${services[$service]}
    for environment in "${environments[@]}"; do
        create_jenkins_job "$service" "$environment" "$port"
        sleep 1
    done
done

# Crear job para E2E tests
echo -e "${YELLOW}📦 Creando job de E2E tests...${NC}"
cat > "/tmp/e2e-tests-staging.xml" << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>End-to-End tests for staging environment</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>ENVIRONMENT</name>
          <description>Environment to test</description>
          <defaultValue>staging</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
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
          <name>*/staging</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>jenkins/Jenkinsfile-e2e</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

curl -s -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
    -H "Content-Type: application/xml" \
    -X POST \
    "${JENKINS_URL}/createItem?name=e2e-tests-staging" \
    --data-binary "@/tmp/e2e-tests-staging.xml"

rm -f "/tmp/e2e-tests-staging.xml"

echo -e "${GREEN}🎉 Configuración de Jenkins completada${NC}"
echo -e "${BLUE}📋 Jobs creados:${NC}"

# Listar jobs creados
for service in "${!services[@]}"; do
    for environment in "${environments[@]}"; do
        echo "  - ${service}-${environment}"
    done
done
echo "  - e2e-tests-staging"