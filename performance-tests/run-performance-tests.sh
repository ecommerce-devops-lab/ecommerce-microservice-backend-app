#!/bin/bash
# performance-tests/run-performance-tests.sh
# Script corregido compatible con todas las versiones de Locust

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
USER_SERVICE_URL="http://localhost:8700"
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Crear directorio de reportes si no existe
mkdir -p ${REPORTS_DIR}

echo -e "${BLUE}🚀 Iniciando Pruebas de Performance para User Service${NC}"

# Verificar versión de Locust
check_locust_version() {
    if command -v locust &> /dev/null; then
        LOCUST_VERSION=$(locust --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
        echo -e "${BLUE}📦 Versión de Locust detectada: ${LOCUST_VERSION}${NC}"
    else
        echo -e "${RED}❌ Locust no está instalado${NC}"
        echo "Instalar con: pip3 install locust"
        exit 1
    fi
}

# Función para verificar si el servicio está disponible
check_service_health() {
    echo -e "${YELLOW}🔍 Verificando disponibilidad del servicio...${NC}"
    
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "${USER_SERVICE_URL}/user-service/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Servicio disponible${NC}"
            return 0
        fi
        
        echo "Intento $attempt/$max_attempts - Esperando que el servicio esté disponible..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ El servicio no está disponible después de $max_attempts intentos${NC}"
    echo "Verifica que user-service esté corriendo en ${USER_SERVICE_URL}"
    exit 1
}

# Función para ejecutar prueba de carga (versión compatible)
run_load_test() {
    local test_name=$1
    local users=$2
    local spawn_rate=$3
    local duration=$4
    local locust_file=${5:-"locustfile.py"}
    
    echo -e "${BLUE}📊 Ejecutando $test_name...${NC}"
    echo "Usuarios: $users, Spawn Rate: $spawn_rate, Duración: $duration"
    echo "Archivo: $locust_file"
    
    # Verificar que el archivo de Locust existe
    if [ ! -f "$locust_file" ]; then
        echo -e "${RED}❌ Archivo $locust_file no encontrado${NC}"
        return 1
    fi
    
    # Comando básico compatible con todas las versiones
    locust \
        --host="$USER_SERVICE_URL" \
        --users=$users \
        --spawn-rate=$spawn_rate \
        --run-time=$duration \
        --headless \
        --html="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.html" \
        --csv="${REPORTS_DIR}/${test_name}_${TIMESTAMP}" \
        --logfile="${REPORTS_DIR}/${test_name}_${TIMESTAMP}.log" \
        --loglevel=INFO \
        -f "$locust_file"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name completado${NC}"
    else
        echo -e "${RED}❌ $test_name falló con código $exit_code${NC}"
        return $exit_code
    fi
}

# Función para crear archivo de Locust específico para cada test
create_specific_locustfile() {
    local test_type=$1
    local output_file="locustfile_${test_type}.py"
    
    case "$test_type" in
        "users")
            cat > "$output_file" << 'EOF'
from locust import HttpUser, task, between
import json
import random
from faker import Faker

fake = Faker()

class UserServiceUser(HttpUser):
    wait_time = between(1, 3)
    host = "http://localhost:8700"
    
    def on_start(self):
        self.user_ids = []
        self.test_users = []
        self.create_test_data()
    
    def create_test_data(self):
        for i in range(5):
            user_data = {
                "firstName": fake.first_name(),
                "lastName": fake.last_name(),
                "email": fake.email(),
                "phone": fake.phone_number()[:15],
                "credentialDto": {
                    "username": f"test_user_{random.randint(1000, 9999)}_{i}",
                    "password": "test123",
                    "roleBasedAuthority": "ROLE_USER",
                    "isEnabled": True,
                    "isAccountNonExpired": True,
                    "isAccountNonLocked": True,
                    "isCredentialsNonExpired": True
                }
            }
            self.test_users.append(user_data)
    
    @task(3)
    def get_all_users(self):
        with self.client.get("/user-service/api/users", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(2)
    def create_user(self):
        user_data = random.choice(self.test_users)
        user_data["credentialDto"]["username"] = f"user_{random.randint(10000, 99999)}"
        
        with self.client.post("/user-service/api/users", json=user_data, catch_response=True) as response:
            if response.status_code == 201:
                try:
                    data = response.json()
                    if "data" in data and "userId" in data["data"]:
                        self.user_ids.append(data["data"]["userId"])
                        response.success()
                except:
                    response.failure("Invalid response format")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(2)
    def get_user_by_id(self):
        if not self.user_ids:
            return
        
        user_id = random.choice(self.user_ids)
        with self.client.get(f"/user-service/api/users/{user_id}", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                if user_id in self.user_ids:
                    self.user_ids.remove(user_id)
                response.failure("User not found")
            else:
                response.failure(f"Got status code {response.status_code}")
EOF
            ;;
        "credentials")
            cat > "$output_file" << 'EOF'
from locust import HttpUser, task, between
import random

class CredentialServiceUser(HttpUser):
    wait_time = between(1, 2)
    host = "http://localhost:8700"
    
    @task(2)
    def get_all_credentials(self):
        with self.client.get("/user-service/api/credentials", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(1)
    def get_credential_by_username(self):
        username = f"test_user_{random.randint(1, 100)}"
        with self.client.get(f"/user-service/api/credentials/username/{username}", catch_response=True) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
EOF
            ;;
        "addresses")
            cat > "$output_file" << 'EOF'
from locust import HttpUser, task, between

class AddressServiceUser(HttpUser):
    wait_time = between(1, 2)
    host = "http://localhost:8700"
    
    @task(3)
    def get_all_addresses(self):
        with self.client.get("/user-service/api/address", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
EOF
            ;;
    esac
    
    echo "$output_file"
}

# Función para ejecutar todas las pruebas
run_all_tests() {
    echo -e "${YELLOW}🧪 Ejecutando suite completa de pruebas de performance${NC}"
    
    # Verificar que locustfile.py existe
    if [ ! -f "locustfile.py" ]; then
        echo -e "${YELLOW}⚠️  locustfile.py no encontrado, usando el archivo por defecto${NC}"
        # Usar el archivo de usuarios como default
        DEFAULT_FILE=$(create_specific_locustfile "users")
        cp "$DEFAULT_FILE" "locustfile.py"
    fi
    
    # Prueba de carga ligera
    run_load_test "light_load" 25 5 "180s" "locustfile.py"
    sleep 10
    
    # Prueba de carga normal
    run_load_test "normal_load" 50 10 "300s" "locustfile.py"
    sleep 10
    
    # Prueba de carga pesada
    run_load_test "heavy_load" 100 20 "300s" "locustfile.py"
    sleep 10
    
    # Prueba de stress
    run_load_test "stress_test" 200 50 "180s" "locustfile.py"
}

# Función para ejecutar pruebas específicas de endpoints
run_endpoint_tests() {
    echo -e "${YELLOW}🎯 Ejecutando pruebas específicas por endpoint${NC}"
    
    # Test específico para usuarios
    USER_FILE=$(create_specific_locustfile "users")
    run_load_test "users_endpoint" 50 10 "240s" "$USER_FILE"
    sleep 10
    
    # Test específico para credenciales
    CRED_FILE=$(create_specific_locustfile "credentials")
    run_load_test "credentials_endpoint" 30 8 "180s" "$CRED_FILE"
    sleep 10
    
    # Test específico para direcciones
    ADDR_FILE=$(create_specific_locustfile "addresses")
    run_load_test "addresses_endpoint" 25 5 "180s" "$ADDR_FILE"
    
    # Limpiar archivos temporales
    rm -f locustfile_*.py
}

# Función para generar reporte consolidado
generate_consolidated_report() {
    echo -e "${BLUE}📈 Generando reporte consolidado...${NC}"
    
    cat > "${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md" << EOF
# Reporte de Pruebas de Performance - User Service

**Fecha:** $(date)
**Servicio:** User Service  
**URL:** $USER_SERVICE_URL

## Archivos Generados

### Reportes HTML:
EOF
    
    ls ${REPORTS_DIR}/*${TIMESTAMP}.html 2>/dev/null | while read file; do
        echo "- $(basename $file)" >> "${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md"
    done
    
    echo "" >> "${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md"
    echo "### Datos CSV:" >> "${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md"
    ls ${REPORTS_DIR}/*${TIMESTAMP}_stats.csv 2>/dev/null | while read file; do
        echo "- $(basename $file)" >> "${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md"
    done
    
    echo -e "${GREEN}✅ Reporte consolidado generado: ${REPORTS_DIR}/performance_summary_${TIMESTAMP}.md${NC}"
}

# Función para analizar resultados
analyze_results() {
    echo -e "${BLUE}🔍 Analizando resultados...${NC}"
    
    if command -v python3 &> /dev/null; then
        python3 << EOF
import pandas as pd
import glob
import os

csv_files = glob.glob("${REPORTS_DIR}/*${TIMESTAMP}_stats.csv")

if csv_files:
    print("📊 Análisis de Resultados:")
    print("=" * 50)
    
    for csv_file in csv_files:
        test_name = os.path.basename(csv_file).replace("_${TIMESTAMP}_stats.csv", "")
        print(f"\\n🔸 {test_name.upper()}:")
        
        try:
            df = pd.read_csv(csv_file)
            if not df.empty:
                total_requests = df['Request Count'].sum()
                avg_response_time = df['Average Response Time'].mean()
                max_response_time = df['Max Response Time'].max()
                failure_rate = (df['Failure Count'].sum() / total_requests * 100) if total_requests > 0 else 0
                
                print(f"  Total Requests: {total_requests:,}")
                print(f"  Avg Response Time: {avg_response_time:.2f}ms")
                print(f"  Max Response Time: {max_response_time:.2f}ms")
                print(f"  Failure Rate: {failure_rate:.2f}%")
                
                if 'Requests/s' in df.columns:
                    avg_rps = df['Requests/s'].mean()
                    print(f"  Average RPS: {avg_rps:.2f}")
        except Exception as e:
            print(f"  Error leyendo {csv_file}: {e}")
else:
    print("No se encontraron archivos CSV para analizar")
EOF
    else
        echo "Python3 no disponible para análisis automático"
        echo "Revisa manualmente los archivos en ${REPORTS_DIR}/"
    fi
}

# Función principal
main() {
    check_locust_version
    
    case "${1:-all}" in
        "health")
            check_service_health
            ;;
        "light")
            check_service_health
            run_load_test "light_load" 25 5 "180s"
            ;;
        "normal")
            check_service_health
            run_load_test "normal_load" 50 10 "300s"
            ;;
        "heavy")
            check_service_health
            run_load_test "heavy_load" 100 20 "300s"
            ;;
        "stress")
            check_service_health
            run_load_test "stress_test" 200 50 "180s"
            ;;
        "endpoints")
            check_service_health
            run_endpoint_tests
            ;;
        "all")
            check_service_health
            run_all_tests
            generate_consolidated_report
            analyze_results
            ;;
        "analyze")
            analyze_results
            ;;
        *)
            echo "Uso: $0 [health|light|normal|heavy|stress|endpoints|all|analyze]"
            echo ""
            echo "Comandos disponibles:"
            echo "  health    - Verificar salud del servicio"
            echo "  light     - Prueba de carga ligera (25 usuarios)"
            echo "  normal    - Prueba de carga normal (50 usuarios)"
            echo "  heavy     - Prueba de carga pesada (100 usuarios)"
            echo "  stress    - Prueba de stress (200 usuarios)"
            echo "  endpoints - Pruebas específicas por endpoint"
            echo "  all       - Ejecutar todas las pruebas"
            echo "  analyze   - Analizar resultados existentes"
            exit 1
            ;;
    esac
}

# Ejecutar función principal con argumentos
main "$@"