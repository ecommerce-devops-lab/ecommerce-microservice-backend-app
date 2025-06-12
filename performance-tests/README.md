# Guía de Pruebas de Performance y Estrés

## Cómo Usar

### Instalación de dependencias
```bash
pip install -r requirements.txt
```

### Configuración inicial
Dar permisos de ejecución al script:
```bash
chmod +x run-performance-tests.sh
```

### Ejecución de pruebas
Asegúrate de que tu aplicación esté corriendo en el puerto 8765 antes de ejecutar las pruebas.

#### Opciones de ejecución:
```bash
# Todas las pruebas
./run-performance-tests.sh

# Solo pruebas de rendimiento
./run-performance-tests.sh performance

# Solo pruebas de estrés
./run-performance-tests.sh stress

# Prueba rápida
./run-performance-tests.sh quick

# Prueba de resistencia (larga duración)
./run-performance-tests.sh endurance
```

## Microservicios Incluidos en las Pruebas

1. **User Service**
   - Gestión de usuarios (`/app/api/users`)
   - Gestión de direcciones (`/app/api/address`)
   - Gestión de credenciales (`/app/api/credentials`)
   - Tokens de verificación (`/app/api/verificationTokens`)

2. **Product Service**
   - Catálogo de productos (`/app/api/products`)
   - Gestión de categorías (`/app/api/categories`)
   - Operaciones CRUD completas

3. **Order Service**
   - Gestión de órdenes (`/app/api/orders`)
   - Gestión de carritos (`/app/api/carts`)
   - Flujo completo de checkout

4. **Payment Service**
   - Procesamiento de pagos (`/app/api/payments`)
   - Estados de pago (PENDING, COMPLETED, etc.)

5. **Favourite Service**
   - Gestión de favoritos (`/app/api/favourites`)
   - Operaciones por usuario

6. **Shipping Service**
   - Order Items (`/app/api/shippings`)
   - Gestión de envíos

## Tipos de Pruebas Implementadas

### Pruebas de Rendimiento
- **Debug Test**: 5 usuarios, 1 min (para verificar funcionamiento)
- **Performance Test**: 75 usuarios, 10 min (carga normal)
- **Load Test**: 100 usuarios, 15 min (carga sostenida)

### Pruebas de Estrés
- **Stress Test**: 300 usuarios, 7.5 min (alta carga)
- **High Stress**: 500 usuarios, 5 min (estrés extremo)
- **Spike Test**: 800 usuarios, 3 min (picos de tráfico)
- **Mega Spike**: 1200 usuarios, 2 min (pico extremo)

### Pruebas Especializadas
- **Checkout Flow**: Flujo completo de compra
- **Catalog Browsing**: Navegación intensiva del catálogo
- **Endurance Test**: 200 usuarios, 30 min (resistencia)

## Ejecución Recomendada
1. **Primero**: Ejecuta debug-test para verificar conectividad
2. **Desarrollo**: Usa performance y load-test
3. **Pre-producción**: Ejecuta stress-test y spike-test
4. **Producción**: Considera endurance-test para validar estabilidad