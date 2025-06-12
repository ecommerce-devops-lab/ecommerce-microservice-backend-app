import random
import time
from locust import HttpUser, task, between, SequentialTaskSet
from faker import Faker

fake = Faker()

class CheckoutFlow(SequentialTaskSet):
    """
    Flujo de compra completo end-to-end:
    1. Añadir productos al carrito
    2. Crear una orden
    3. Procesar el pago
    4. Crear shipping/order items
    """
    
    def on_start(self):
        """Inicializa las variables para el flujo de checkout."""
        self.cart_id = None
        self.order_id = None
        self.payment_id = None
        self.order_fee = round(random.uniform(50.0, 1000.0), 2)

    @task
    def add_to_cart(self):
        """Añadir productos al carrito usando el proxy-client"""
        cart_data = {
            "userId": self.user.user_id,
            "orderDtos": []
        }
        
        with self.client.post(
            "/app/api/carts",
            json=cart_data,
            headers=self.user.auth_headers,
            name="Create Cart",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    self.cart_id = response.json().get("cartId")
                    response.success()
                except:
                    response.failure("Invalid response format")
                    self.interrupt()
            else:
                response.failure(f"Failed to create cart: {response.status_code}")
                self.interrupt()

    @task
    def create_order(self):
        """Crear una orden"""
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
            "/app/api/orders",
            json=order_data,
            headers=self.user.auth_headers,
            name="Create Order",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    self.order_id = response.json().get("orderId")
                    response.success()
                except:
                    response.failure("Invalid response format")
                    self.interrupt()
            else:
                response.failure(f"Failed to create order: {response.status_code}")
                self.interrupt()

    @task
    def process_payment(self):
        """Procesar el pago de la orden"""
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
            "/app/api/payments",
            json=payment_data,
            headers=self.user.auth_headers,
            name="Process Payment",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    self.payment_id = response.json().get("paymentId")
                    response.success()
                except:
                    response.failure("Invalid response format")
            else:
                response.failure(f"Failed to process payment: {response.status_code}")
        
        self.interrupt()

    @task
    def create_shipping_item(self):
        """Crear order items para shipping"""
        if not self.order_id:
            return
        
        # Create an order item
        product_id = random.randint(1, 4)
        order_item_data = {
            "productId": product_id,
            "orderId": self.order_id,
            "orderedQuantity": random.randint(1, 5)
        }

        with self.client.post(
            "/app/api/shippings",
            json=order_item_data,
            headers=self.user.auth_headers,
            name="Create Order Item",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to create order item: {response.status_code}")


class EcommerceUser(HttpUser):
    wait_time = between(1, 5)
    jwt_token = None
    user_id = None
    auth_headers = {}

    def on_start(self):
        """Autenticar y obtener datos del usuario al iniciar"""
        self.authenticate_user()

    def authenticate_user(self):
        """Autenticar con credenciales existentes y obtener user_id"""
        usernames = ["selimhorri", "amineladjimi", "omarderouiche", "admin"]
        username = random.choice(usernames)
        
        try:
            auth_response = self.client.post(
                "/app/api/authenticate",
                json={
                    "username": username,
                    "password": "password"
                },
                name="Authenticate"
            )
            
            if auth_response.status_code == 200:
                self.jwt_token = auth_response.json().get("jwtToken")
                self.auth_headers = {"Authorization": f"Bearer {self.jwt_token}"}
                
                # Get user_id using the username
                user_response = self.client.get(
                    f"/app/api/users/username/{username}",
                    headers=self.auth_headers,
                    name="Get User by Username"
                )
                
                if user_response.status_code == 200:
                    self.user_id = user_response.json().get("userId")
                else:
                    print(f"Failed to get user info for {username}")
                    self.stop()
            else:
                print(f"Authentication failed for {username}: {auth_response.status_code}")
                self.stop()
                
        except Exception as e:
            print(f"Authentication error: {e}")
            self.stop()

    # USER SERVICE TASKS
    @task(3)
    def browse_users(self):
        """Navegar por usuarios (admin functionality)"""
        if not self.auth_headers:
            return
            
        self.client.get("/app/api/users", headers=self.auth_headers, name="Get All Users")
        
        # View details of a specific user
        user_id = random.randint(1, 4)
        self.client.get(f"/app/api/users/{user_id}", headers=self.auth_headers, name="Get User Details")

    @task(2)
    def manage_addresses(self):
        """Gestionar direcciones del usuario"""
        if not self.auth_headers:
            return
            
        # See all addresses
        self.client.get("/app/api/address", headers=self.auth_headers, name="Get All Addresses")
        
        # Create new address
        address_data = {
            "fullAddress": fake.address(),
            "postalCode": fake.postcode(),
            "city": fake.city(),
            "userDto": {"userId": self.user_id}
        }
        
        self.client.post("/app/api/address", json=address_data, headers=self.auth_headers, name="Create Address")

    # PRODUCT SERVICE TASKS
    @task(8)
    def browse_catalog(self):
        """Navegar por el catálogo de productos"""
        # See all categories
        self.client.get("/app/api/categories", name="Get All Categories")
        
        # View details of a specific category
        category_id = random.randint(1, 5)
        self.client.get(f"/app/api/categories/{category_id}", name="Get Category Details")
        
        # See all products
        self.client.get("/app/api/products", name="Get All Products")
        
        # View details of a specific product
        product_id = random.randint(1, 4)
        self.client.get(f"/app/api/products/{product_id}", name="Get Product Details")

    @task(1)
    def manage_products(self):
        """Gestionar productos (funcionalidad admin)"""
        if not self.auth_headers:
            return
            
        # Create new product
        product_data = {
            "productTitle": fake.word().title(),
            "imageUrl": fake.image_url(),
            "sku": fake.uuid4()[:12],
            "priceUnit": round(random.uniform(10.0, 1000.0), 2),
            "quantity": random.randint(1, 100),
            "categoryDto": {"categoryId": random.randint(1, 4)}
        }
        
        self.client.post("/app/api/products", json=product_data, headers=self.auth_headers, name="Create Product")

    # FAVOURITE SERVICE TASKS
    @task(4)
    def manage_favourites(self):
        """Gestionar productos favoritos"""
        if not self.auth_headers or not self.user_id:
            return

        # See all favorites
        self.client.get("/app/api/favourites", headers=self.auth_headers, name="Get All Favourites")

        # Add product to favorites
        favourite_data = {
            "userId": self.user_id,
            "productId": random.randint(1, 4),
            "likeDate": "2024-12-01T10:00:00"
        }
        
        self.client.post("/app/api/favourites", json=favourite_data, headers=self.auth_headers, name="Add to Favourites")

    # ORDER SERVICE TASKS
    @task(3)
    def browse_orders(self):
        """Navegar por órdenes"""
        if not self.auth_headers:
            return
            
        # View all orders
        self.client.get("/app/api/orders", headers=self.auth_headers, name="Get All Orders")
        
        # See all carts
        self.client.get("/app/api/carts", headers=self.auth_headers, name="Get All Carts")

    # PAYMENT SERVICE TASKS
    @task(2)
    def browse_payments(self):
        """Navegar por pagos"""
        if not self.auth_headers:
            return
            
        # See all payments
        self.client.get("/app/api/payments", headers=self.auth_headers, name="Get All Payments")
        
        # View details of a specific payment
        payment_id = random.randint(1, 4)
        self.client.get(f"/app/api/payments/{payment_id}", headers=self.auth_headers, name="Get Payment Details")

    # SHIPPING SERVICE TASKS
    @task(2)
    def browse_shipping(self):
        """Navegar por order items/shipping"""
        if not self.auth_headers:
            return
            
        # View all order items
        self.client.get("/app/api/shippings", headers=self.auth_headers, name="Get All Order Items")

    # COMPLETE CHECKOUT FLOW
    @task(1)
    def complete_checkout(self):
        """Ejecutar flujo completo de checkout"""
        if self.jwt_token and self.user_id:
            self.schedule_task(CheckoutFlow)

    # CREDENTIAL MANAGEMENT
    @task(1)
    def manage_credentials(self):
        """Gestionar credenciales (funcionalidad admin)"""
        if not self.auth_headers:
            return
            
        # View all credentials
        self.client.get("/app/api/credentials", headers=self.auth_headers, name="Get All Credentials")
        
        # View verification tokens
        self.client.get("/app/api/verificationTokens", headers=self.auth_headers, name="Get Verification Tokens")


class HighLoadUser(EcommerceUser):
    """Usuario para pruebas de alto rendimiento y estrés"""
    wait_time = between(0.5, 2)
    
    @task(20)
    def intensive_catalog_browsing(self):
        """Navegación intensiva del catálogo"""
        for _ in range(3):
            self.browse_catalog()
            time.sleep(0.1)
    
    @task(10)
    def intensive_product_operations(self):
        """Operaciones intensivas con productos"""
        self.browse_catalog()
        if self.auth_headers:
            self.manage_favourites()
            self.manage_products()


class AdminUser(EcommerceUser):
    """Usuario administrador para operaciones específicas"""
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
                name="Admin Authenticate"
            )
            
            if auth_response.status_code == 200:
                self.jwt_token = auth_response.json().get("jwtToken")
                self.auth_headers = {"Authorization": f"Bearer {self.jwt_token}"}
                self.user_id = 4
            else:
                self.stop()
        except Exception as e:
            print(f"Admin authentication error: {e}")
            self.stop()
    
    @task(5)
    def admin_operations(self):
        """Operaciones específicas de administrador"""
        if not self.auth_headers:
            return
            
        self.browse_users()
        self.manage_credentials()
        self.browse_orders()
        self.browse_payments()
        self.browse_shipping()