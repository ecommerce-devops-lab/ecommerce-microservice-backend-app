import random
import time
from locust import HttpUser, task, between, SequentialTaskSet
from faker import Faker

fake = Faker()

class CheckoutFlow(SequentialTaskSet):
    """
    Flujo de compra usando las rutas directas de microservicios a través del API Gateway
    """
    
    def on_start(self):
        """Inicializa las variables para el flujo de checkout."""
        self.cart_id = None
        self.order_id = None
        self.payment_id = None
        self.order_fee = round(random.uniform(50.0, 1000.0), 2)

    @task
    def add_to_cart(self):
        """Añadir productos al carrito usando order-service directo"""
        cart_data = {
            "userId": self.user.user_id,
            "orderDtos": []
        }
        
        with self.client.post(
            "/order-service/api/carts",
            json=cart_data,
            headers=self.user.auth_headers,
            name="Create Cart (Order Service)",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    resp_json = response.json()
                    if isinstance(resp_json, dict):
                        if 'collection' in resp_json and resp_json['collection']:
                            self.cart_id = resp_json['collection'][0].get("cartId")
                        else:
                            self.cart_id = resp_json.get("cartId")
                    response.success()
                except Exception as e:
                    response.failure(f"Invalid response format: {e}")
                    self.interrupt()
            else:
                response.failure(f"Failed to create cart: {response.status_code}")
                self.interrupt()

    @task
    def create_order(self):
        """Crear una orden usando order-service"""
        if not self.cart_id:
            self.interrupt()
            return
        
        order_data = {
            "orderDate": "2024-12-01T10:00:00",
            "orderDesc": f"Order from user {self.user.user_id}",
            "orderFee": self.order_fee,
            "cartDto": {
                "cartId": self.cart_id,
                "userId": self.user.user_id
            }
        }

        with self.client.post(
            "/order-service/api/orders",
            json=order_data,
            headers=self.user.auth_headers,
            name="Create Order",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    resp_json = response.json()
                    if isinstance(resp_json, dict):
                        if 'collection' in resp_json and resp_json['collection']:
                            self.order_id = resp_json['collection'][0].get("orderId")
                        else:
                            self.order_id = resp_json.get("orderId")
                    response.success()
                except Exception as e:
                    response.failure(f"Invalid response format: {e}")
                    self.interrupt()
            else:
                response.failure(f"Failed to create order: {response.status_code}")
                self.interrupt()

    @task
    def process_payment(self):
        """Procesar el pago usando payment-service"""
        if not self.order_id:
            self.interrupt()
            return
        
        payment_data = {
            "isPayed": True,
            "paymentStatus": "COMPLETED",
            "orderDto": {
                "orderId": self.order_id,
                "orderFee": self.order_fee
            }
        }

        with self.client.post(
            "/payment-service/api/payments",
            json=payment_data,
            headers=self.user.auth_headers,
            name="Process Payment",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to process payment: {response.status_code}")
        
        self.interrupt()


class EcommerceUser(HttpUser):
    wait_time = between(2, 6)
    jwt_token = None
    user_id = None
    auth_headers = {}

    def on_start(self):
        """Autenticar y obtener datos del usuario al iniciar"""
        self.authenticate_user()

    def authenticate_user(self):
        """Autenticar usando las rutas reales del sistema"""
        usernames = ["selimhorri", "amineladjimi", "omarderouiche", "admin"]
        username = random.choice(usernames)
        
        try:
            auth_response = self.client.post(
                "/app/api/authenticate",
                json={
                    "username": username,
                    "password": "password"
                },
                name="Authenticate (Proxy)",
                catch_response=True
            )
            
            if auth_response.status_code == 200:
                try:
                    self.jwt_token = auth_response.json().get("jwtToken")
                    self.auth_headers = {"Authorization": f"Bearer {self.jwt_token}"}
                    
                    user_response = self.client.get(
                        f"/user-service/api/users/username/{username}",
                        headers=self.auth_headers,
                        name="Get User by Username"
                    )
                    
                    if user_response.status_code == 200:
                        user_data = user_response.json()
                        if 'data' in user_data:
                            self.user_id = user_data['data'].get("userId")
                        else:
                            self.user_id = user_data.get("userId")
                    
                    auth_response.success()
                except Exception as e:
                    auth_response.failure(f"Auth parsing error: {e}")
                    self.stop()
            else:
                auth_response.failure(f"Auth failed: {auth_response.status_code}")
                user_mapping = {"selimhorri": 1, "amineladjimi": 2, "omarderouiche": 3, "admin": 4}
                self.user_id = user_mapping.get(username, 1)
                self.auth_headers = {}
                
        except Exception as e:
            print(f"Authentication error: {e}")
            self.user_id = random.randint(1, 4)
            self.auth_headers = {}

    # PRODUCT SERVICE TASKS
    @task(10)
    def browse_products_catalog(self):
        """Navegar por productos usando product-service directamente"""
        self.client.get("/product-service/api/products", name="Get All Products")
        
        product_id = random.randint(1, 4)
        self.client.get(f"/product-service/api/products/{product_id}", name="Get Product Details")

    @task(8)
    def browse_categories(self):
        """Navegar por categorías usando product-service"""
        self.client.get("/product-service/api/categories", name="Get All Categories")
        
        category_id = random.randint(1, 5)
        self.client.get(f"/product-service/api/categories/{category_id}", name="Get Category Details")

    # USER SERVICE TASKS
    @task(4)
    def browse_users(self):
        """Navegar por usuarios usando user-service"""
        if self.auth_headers:
            self.client.get("/user-service/api/users", headers=self.auth_headers, name="Get All Users")
            
            user_id = random.randint(1, 4)
            self.client.get(f"/user-service/api/users/{user_id}", headers=self.auth_headers, name="Get User Details")

    @task(3)
    def manage_addresses(self):
        """Gestionar direcciones usando user-service"""
        if self.auth_headers:
            self.client.get("/user-service/api/address", headers=self.auth_headers, name="Get All Addresses")

    # ORDER SERVICE TASKS
    @task(6)
    def browse_orders(self):
        """Navegar por órdenes usando order-service"""
        self.client.get("/order-service/api/orders", headers=self.auth_headers, name="Get All Orders")
        
        self.client.get("/order-service/api/carts", headers=self.auth_headers, name="Get All Carts")

    # PAYMENT SERVICE TASKS
    @task(4)
    def browse_payments(self):
        """Navegar por pagos usando payment-service"""
        if self.auth_headers:
            self.client.get("/payment-service/api/payments", headers=self.auth_headers, name="Get All Payments")
            
            payment_id = random.randint(1, 4)
            self.client.get(f"/payment-service/api/payments/{payment_id}", headers=self.auth_headers, name="Get Payment Details")

    # FAVOURITE SERVICE TASKS
    @task(3)
    def manage_favourites(self):
        """Gestionar favoritos usando favourite-service"""
        if self.auth_headers and self.user_id:
            self.client.get("/favourite-service/api/favourites", headers=self.auth_headers, name="Get All Favourites")

            favourite_data = {
                "userId": self.user_id,
                "productId": random.randint(1, 4),
                "likeDate": "2024-12-01T10:00:00"
            }
            
            self.client.post("/favourite-service/api/favourites", json=favourite_data, headers=self.auth_headers, name="Add to Favourites")

    # SHIPPING SERVICE TASKS
    @task(2)
    def browse_shipping(self):
        """Navegar por order items usando shipping-service"""
        if self.auth_headers:
            self.client.get("/shipping-service/api/shippings", headers=self.auth_headers, name="Get All Order Items")

    # CHECKOUT FLOW
    @task(1)
    def complete_checkout(self):
        """Ejecutar flujo completo de checkout"""
        if self.user_id:
            self.schedule_task(CheckoutFlow)

    # HEALTH CHECKS
    @task(2)
    def health_checks(self):
        """Verificar salud de los servicios"""
        services = ["product-service", "user-service", "order-service", "payment-service", "favourite-service"]
        service = random.choice(services)
        
        health_url = f"/{service}/actuator/health"
        main_url = f"/{service}/api"
        
        response = self.client.get(health_url, name=f"Health Check - {service}", catch_response=True)
        if response.status_code == 404:
            response.failure("Health endpoint not available")
            self.client.get(main_url, name=f"Service Check - {service}")
        else:
            response.success()


class HighLoadUser(EcommerceUser):
    """Usuario para pruebas de alta carga"""
    wait_time = between(1, 3)
    
    @task(15)
    def intensive_browsing(self):
        """Navegación intensiva"""
        self.browse_products_catalog()
        time.sleep(0.5)
        self.browse_categories()


class AdminUser(EcommerceUser):
    """Usuario para operaciones administrativas"""
    weight = 1
    
    def on_start(self):
        """Autenticar como admin"""
        try:
            auth_response = self.client.post(
                "/app/api/authenticate",
                json={
                    "username": "admin",
                    "password": "password"
                },
                name="Admin Authenticate",
                catch_response=True
            )
            
            if auth_response.status_code == 200:
                self.jwt_token = auth_response.json().get("jwtToken")
                self.auth_headers = {"Authorization": f"Bearer {self.jwt_token}"}
                self.user_id = 4
                auth_response.success()
            else:
                auth_response.failure("Admin auth failed")
                self.user_id = 4
                self.auth_headers = {}
        except Exception as e:
            print(f"Admin authentication error: {e}")
            self.user_id = 4
            self.auth_headers = {}
    
    @task(8)
    def admin_monitoring(self):
        """Operaciones de monitoreo administrativo"""
        self.browse_users()
        self.browse_orders()
        self.browse_payments()