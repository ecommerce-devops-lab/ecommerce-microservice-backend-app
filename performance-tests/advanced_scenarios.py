"""
Escenarios avanzados de pruebas de performance
Incluye patrones de carga realistas y casos de uso específicos
"""

from locust import HttpUser, task, between, events
import random
import json
import time
from faker import Faker
import logging

fake = Faker()

class DatabaseStressUser(HttpUser):
    """
    Escenario específico para probar la base de datos bajo carga
    Simula operaciones que requieren consultas complejas
    """
    wait_time = between(0.5, 2)
    host = "http://localhost:8700"
    
    def on_start(self):
        """Configuración inicial"""
        self.created_users = []
        self.search_terms = [
            "john", "jane", "admin", "user", "test",
            "smith", "doe", "johnson", "brown", "davis"
        ]
    
    @task(4)
    def search_users_by_name(self):
        """Búsquedas que generan consultas LIKE en la base de datos"""
        search_term = random.choice(self.search_terms)
        
        # Simular búsqueda por nombre (aunque no esté implementada, muestra el patrón)
        with self.client.get(
            f"/user-service/api/users",
            params={"search": search_term},
            catch_response=True
        ) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")
    
    @task(3)
    def paginated_user_listing(self):
        """Prueba paginación que estresa las consultas con OFFSET/LIMIT"""
        page = random.randint(0, 10)
        size = random.choice([10, 20, 50])
        
        with self.client.get(
            f"/user-service/api/users",
            params={"page": page, "size": size},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Pagination failed: {response.status_code}")
    
    @task(2)
    def concurrent_user_creation(self):
        """Creación concurrente para probar locks de base de datos"""
        user_data = {
            "firstName": fake.first_name(),
            "lastName": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number()[:15],
            "credentialDto": {
                "username": f"concurrent_user_{random.randint(100000, 999999)}",
                "password": "password123",
                "roleBasedAuthority": "ROLE_USER",
                "isEnabled": True,
                "isAccountNonExpired": True,
                "isAccountNonLocked": True,
                "isCredentialsNonExpired": True
            }
        }
        
        with self.client.post(
            "/user-service/api/users",
            json=user_data,
            catch_response=True
        ) as response:
            if response.status_code == 201:
                try:
                    data = response.json()
                    self.created_users.append(data["data"]["userId"])
                    response.success()
                except:
                    response.failure("Invalid response format")
            else:
                response.failure(f"Creation failed: {response.status_code}")

class MemoryLeakDetectionUser(HttpUser):
    """
    Escenario para detectar memory leaks
    Ejecuta operaciones repetitivas que podrían acumular memoria
    """
    wait_time = between(0.1, 0.5)  # Más agresivo
    host = "http://localhost:8700"
    
    @task(5)
    def rapid_user_creation_and_deletion(self):
        """Creación y eliminación rápida para detectar leaks"""
        # Crear usuario
        user_data = {
            "firstName": fake.first_name(),
            "lastName": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number()[:15],
            "credentialDto": {
                "username": f"leak_test_{random.randint(1000000, 9999999)}",
                "password": "test123",
                "roleBasedAuthority": "ROLE_USER",
                "isEnabled": True,
                "isAccountNonExpired": True,
                "isAccountNonLocked": True,
                "isCredentialsNonExpired": True
            }
        }
        
        # Crear
        with self.client.post("/user-service/api/users", json=user_data) as response:
            if response.status_code == 201:
                try:
                    user_id = response.json()["data"]["userId"]
                    # Inmediatamente eliminar
                    self.client.delete(f"/user-service/api/users/{user_id}")
                except:
                    pass
    
    @task(3)
    def large_payload_requests(self):
        """Requests con payloads grandes para probar manejo de memoria"""
        large_user_data = {
            "firstName": "A" * 100,  # Nombres largos
            "lastName": "B" * 100,
            "email": f"{'test' * 20}@example.com",
            "phone": "1234567890" * 5,  # Número largo
            "credentialDto": {
                "username": f"large_payload_user_{random.randint(100000, 999999)}",
                "password": "password123" * 10,  # Password largo
                "roleBasedAuthority": "ROLE_USER",
                "isEnabled": True,
                "isAccountNonExpired": True,
                "isAccountNonLocked": True,
                "isCredentialsNonExpired": True
            }
        }
        
        self.client.post("/user-service/api/users", json=large_user_data)

class ErrorHandlingStressUser(HttpUser):
    """
    Escenario para probar manejo de errores bajo carga
    Genera intencionalmente errores para verificar la robustez
    """
    wait_time = between(0.2, 1)
    host = "http://localhost:8700"
    
    @task(3)
    def invalid_user_requests(self):
        """Requests con datos inválidos"""
        invalid_scenarios = [
            # Email inválido
            {
                "firstName": "Test",
                "lastName": "User",
                "email": "invalid-email",
                "phone": "123456789"
            },
            # Datos faltantes
            {
                "firstName": "",
                "lastName": "",
                "email": "",
                "phone": ""
            },
            # Credenciales inválidas
            {
                "firstName": "Test",
                "lastName": "User", 
                "email": "test@example.com",
                "phone": "123456789",
                "credentialDto": {
                    "username": "",  # Username vacío
                    "password": "",  # Password vacío
                    "roleBasedAuthority": "INVALID_ROLE"
                }
            }
        ]
        
        invalid_data = random.choice(invalid_scenarios)
        with self.client.post(
            "/user-service/api/users",
            json=invalid_data,
            catch_response=True
        ) as response:
            # Esperamos error 400
            if response.status_code == 400:
                response.success()
            else:
                response.failure(f"Expected 400, got {response.status_code}")
    
    @task(2)
    def nonexistent_resource_requests(self):
        """Requests a recursos que no existen"""
        scenarios = [
            ("GET", f"/user-service/api/users/{random.randint(99999, 999999)}"),
            ("PUT", f"/user-service/api/users/{random.randint(99999, 999999)}"),
            ("DELETE", f"/user-service/api/users/{random.randint(99999, 999999)}"),
            ("GET", f"/user-service/api/credentials/{random.randint(99999, 999999)}"),
            ("GET", f"/user-service/api/address/{random.randint(99999, 999999)}")
        ]
        
        method, endpoint = random.choice(scenarios)
        
        with self.client.request(
            method, endpoint,
            catch_response=True
        ) as response:
            # Esperamos 404
            if response.status_code == 404:
                response.success()
            else:
                response.failure(f"Expected 404, got {response.status_code}")
    
    @task(1)
    def malformed_requests(self):
        """Requests malformados para probar robustez"""
        malformed_scenarios = [
            # JSON malformado
            '{"firstName": "Test", "lastName":}',
            # Tipo de datos incorrecto
            '{"firstName": 123, "lastName": true}',
            # Estructura incorrecta
            '{"wrong": "structure"}'
        ]
        
        malformed_data = random.choice(malformed_scenarios)
        
        with self.client.post(
            "/user-service/api/users",
            data=malformed_data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            # Esperamos error 400
            if response.status_code == 400:
                response.success()
            else:
                response.failure(f"Expected 400, got {response.status_code}")

class RealisticBusinessScenarioUser(HttpUser):
    """
    Escenario que simula un flujo de negocio realista
    Combina múltiples operaciones como lo haría un usuario real
    """
    wait_time = between(2, 5)  # Más realista para usuarios humanos
    host = "http://localhost:8700"
    
    def on_start(self):
        """Configuración del usuario"""
        self.user_session_data = {
            "username": f"business_user_{random.randint(1000, 9999)}",
            "user_id": None,
            "addresses": []
        }
    
    @task(10)
    def complete_user_registration_flow(self):
        """Flujo completo de registro de usuario"""
        # 1. Verificar disponibilidad de username
        username = f"new_user_{random.randint(10000, 99999)}"
        self.client.get(f"/user-service/api/credentials/username/{username}")
        
        # Pausa realista (usuario pensando)
        time.sleep(random.uniform(1, 3))
        
        # 2. Crear usuario
        user_data = {
            "firstName": fake.first_name(),
            "lastName": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number()[:15],
            "credentialDto": {
                "username": username,
                "password": "securepassword123",
                "roleBasedAuthority": "ROLE_USER",
                "isEnabled": True,
                "isAccountNonExpired": True,
                "isAccountNonLocked": True,
                "isCredentialsNonExpired": True
            }
        }
        
        with self.client.post("/user-service/api/users", json=user_data) as response:
            if response.status_code == 201:
                try:
                    self.user_session_data["user_id"] = response.json()["data"]["userId"]
                except:
                    pass
        
        # Pausa realista
        time.sleep(random.uniform(1, 2))
        
        # 3. Verificar creación
        if self.user_session_data["user_id"]:
            self.client.get(f"/user-service/api/users/{self.user_session_data['user_id']}")
    
    @task(5)
    def user_profile_management(self):
        """Gestión típica del perfil de usuario"""
        if not self.user_session_data["user_id"]:
            return
        
        # Ver perfil actual
        self.client.get(f"/user-service/api/users/{self.user_session_data['user_id']}")
        
        # Pausa (usuario revisando información)
        time.sleep(random.uniform(2, 4))
        
        # Actualizar información ocasionalmente
        if random.random() < 0.3:  # 30% de probabilidad
            updated_data = {
                "userId": self.user_session_data["user_id"],
                "firstName": fake.first_name(),
                "lastName": fake.last_name(),
                "email": fake.email(),
                "phone": fake.phone_number()[:15]
            }
            self.client.put("/user-service/api/users", json=updated_data)
    
    @task(3)
    def admin_user_browsing(self):
        """Simulación de usuario administrador navegando"""
        # Ver lista de usuarios (paginada)
        page = random.randint(0, 5)
        self.client.get("/user-service/api/users", params={"page": page, "size": 20})
        
        # Pausa (admin revisando lista)
        time.sleep(random.uniform(3, 6))
        
        # Ver detalles de algunos usuarios
        for _ in range(random.randint(1, 3)):
            user_id = random.randint(1, 50)
            self.client.get(f"/user-service/api/users/{user_id}")
            time.sleep(random.uniform(1, 2))
        
        # Ver credenciales ocasionalmente
        if random.random() < 0.4:  # 40% de probabilidad
            self.client.get("/user-service/api/credentials")

# Configuración de eventos para métricas personalizadas
@events.request.add_listener
def on_request(request_type, name, response_time, response_length, exception, context, **kwargs):
    """Captura métricas personalizadas durante las pruebas"""
    if exception:
        logging.error(f"Request failed: {name} - {exception}")
    
    # Log requests lentos
    if response_time > 5000:  # > 5 segundos
        logging.warning(f"Slow request detected: {name} took {response_time}ms")
    
    # Log responses grandes
    if response_length and response_length > 1024 * 100:  # > 100KB
        logging.info(f"Large response: {name} returned {response_length} bytes")

@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Configuración al inicio de las pruebas"""
    logging.info("🚀 Iniciando pruebas de performance avanzadas")
    logging.info(f"Target host: {environment.host}")

@events.test_stop.add_listener  
def on_test_stop(environment, **kwargs):
    """Resumen al final de las pruebas"""
    logging.info("🏁 Pruebas de performance completadas")
    
    # Estadísticas básicas
    stats = environment.stats
    logging.info(f"Total requests: {stats.total.num_requests}")
    logging.info(f"Total failures: {stats.total.num_failures}")
    logging.info(f"Average response time: {stats.total.avg_response_time:.2f}ms")
    logging.info(f"95th percentile: {stats.total.get_response_time_percentile(0.95):.2f}ms")

# Configuración para ejecutar escenarios específicos
if __name__ == "__main__":
    import sys
    
    # Permitir seleccionar escenario desde línea de comandos
    scenario = sys.argv[1] if len(sys.argv) > 1 else "realistic"
    
    scenarios = {
        "database": DatabaseStressUser,
        "memory": MemoryLeakDetectionUser, 
        "errors": ErrorHandlingStressUser,
        "realistic": RealisticBusinessScenarioUser
    }
    
    selected_scenario = scenarios.get(scenario, RealisticBusinessScenarioUser)
    print(f"Ejecutando escenario: {scenario}")
    print(f"Clase de usuario: {selected_scenario.__name__}")