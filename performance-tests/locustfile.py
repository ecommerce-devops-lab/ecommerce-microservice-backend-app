from locust import HttpUser, task, between
import json
import random
from faker import Faker

fake = Faker()

class UserServiceUser(HttpUser):
    """
    Pruebas de performance para el microservicio User Service
    Simula casos de uso reales del sistema de usuarios
    """
    wait_time = between(1, 3)  # Tiempo de espera entre requests
    host = "http://localhost:8700"  # URL del user-service
    
    def on_start(self):
        """Se ejecuta al inicio de cada usuario virtual"""
        self.user_ids = []
        self.test_users = []
        self.create_test_data()
    
    def create_test_data(self):
        """Crea datos de prueba para usar en los tests"""
        for i in range(5):
            user_data = {
                "firstName": fake.first_name(),
                "lastName": fake.last_name(),
                "email": fake.email(),
                "phone": fake.phone_number()[:15],  # Limitar longitud
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
        """Test: Obtener todos los usuarios (operación más frecuente)"""
        with self.client.get(
            "/user-service/api/users",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if "data" in data:
                        response.success()
                    else:
                        response.failure("Response missing 'data' field")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(2)
    def create_user(self):
        """Test: Crear nuevo usuario"""
        user_data = random.choice(self.test_users)
        # Hacer username único para cada request
        user_data["credentialDto"]["username"] = f"user_{random.randint(10000, 99999)}"
        
        with self.client.post(
            "/user-service/api/users",
            json=user_data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 201:
                try:
                    data = response.json()
                    if "data" in data and "userId" in data["data"]:
                        self.user_ids.append(data["data"]["userId"])
                        response.success()
                    else:
                        response.failure("Response missing user data")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(2)
    def get_user_by_id(self):
        """Test: Obtener usuario por ID"""
        if not self.user_ids:
            # Si no tenemos IDs, crear un usuario primero
            self.create_user()
            if not self.user_ids:
                return
        
        user_id = random.choice(self.user_ids)
        with self.client.get(
            f"/user-service/api/users/{user_id}",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if "data" in data:
                        response.success()
                    else:
                        response.failure("Response missing 'data' field")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            elif response.status_code == 404:
                # Usuario no encontrado, remover de la lista
                if user_id in self.user_ids:
                    self.user_ids.remove(user_id)
                response.failure("User not found")
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(1)
    def update_user(self):
        """Test: Actualizar usuario existente"""
        if not self.user_ids:
            return
        
        user_id = random.choice(self.user_ids)
        updated_data = {
            "userId": user_id,
            "firstName": fake.first_name(),
            "lastName": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number()[:15]
        }
        
        with self.client.put(
            "/user-service/api/users",
            json=updated_data,
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(1)
    def get_user_by_username(self):
        """Test: Buscar usuario por username"""
        if not self.test_users:
            return
            
        username = f"test_user_{random.randint(1000, 9999)}"
        with self.client.get(
            f"/user-service/api/users/username/{username}",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                # Es esperado que muchos usuarios no existan
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

class CredentialServiceUser(HttpUser):
    """
    Pruebas de performance para endpoints de credenciales
    """
    wait_time = between(1, 2)
    host = "http://localhost:8700"
    
    @task(2)
    def get_all_credentials(self):
        """Test: Obtener todas las credenciales"""
        with self.client.get(
            "/user-service/api/credentials",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")
    
    @task(1)
    def get_credential_by_username(self):
        """Test: Buscar credencial por username"""
        username = f"test_user_{random.randint(1, 100)}"
        with self.client.get(
            f"/user-service/api/credentials/username/{username}",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

class AddressServiceUser(HttpUser):
    """
    Pruebas de performance para endpoints de direcciones
    """
    wait_time = between(1, 2)
    host = "http://localhost:8700"
    
    @task(3)
    def get_all_addresses(self):
        """Test: Obtener todas las direcciones"""
        with self.client.get(
            "/user-service/api/address",
            headers={"Content-Type": "application/json"},
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Got status code {response.status_code}")

# Escenario de carga mixta
class MixedWorkloadUser(HttpUser):
    """
    Escenario que combina diferentes tipos de operaciones
    para simular carga real del sistema
    """
    wait_time = between(0.5, 2)
    host = "http://localhost:8700"
    
    tasks = [
        UserServiceUser,
        CredentialServiceUser,
        AddressServiceUser
    ]
    
    def on_start(self):
        """Configuración inicial para carga mixta"""
        self.user_data = {
            "firstName": fake.first_name(),
            "lastName": fake.last_name(),
            "email": fake.email(),
            "phone": fake.phone_number()[:15],
            "credentialDto": {
                "username": f"mixed_user_{random.randint(10000, 99999)}",
                "password": "test123",
                "roleBasedAuthority": "ROLE_USER",
                "isEnabled": True,
                "isAccountNonExpired": True,
                "isAccountNonLocked": True,
                "isCredentialsNonExpired": True
            }
        }
    
    @task(5)
    def browse_users(self):
        """Simula navegación típica de usuarios"""
        # Obtener lista de usuarios
        self.client.get("/user-service/api/users")
        
        # Pausa breve (usuario leyendo)
        self.wait()
        
        # Buscar un usuario específico
        user_id = random.randint(1, 10)
        self.client.get(f"/user-service/api/users/{user_id}")
    
    @task(2)
    def user_registration_flow(self):
        """Simula el flujo completo de registro de usuario"""
        # Verificar si username existe
        username = self.user_data["credentialDto"]["username"]
        self.client.get(f"/user-service/api/credentials/username/{username}")
        
        # Crear usuario
        self.client.post("/user-service/api/users", json=self.user_data)
    
    @task(1)
    def admin_operations(self):
        """Simula operaciones administrativas"""
        # Ver todas las credenciales
        self.client.get("/user-service/api/credentials")
        
        # Ver todas las direcciones
        self.client.get("/user-service/api/address")