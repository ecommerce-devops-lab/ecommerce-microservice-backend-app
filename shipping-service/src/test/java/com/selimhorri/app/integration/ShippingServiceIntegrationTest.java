package com.selimhorri.app.integration;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.cloud.contract.wiremock.AutoConfigureWireMock;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.repository.OrderItemRepository;

/**
 * Pruebas de integración para validar la comunicación entre shipping-service y
 * product-service.
 * 
 * Estas pruebas validan:
 * 1. La comunicación con servicios externos (product-service, order-service)
 * 2. El comportamiento end-to-end de los endpoints
 * 3. El manejo de errores en la comunicación entre servicios
 * 
 * @author Sistema de pruebas
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWireMock(port = 0)
@ActiveProfiles("integration-test")
@Transactional
@DisplayName("Shipping Service Integration Tests")
class ShippingServiceIntegrationTest {

        @LocalServerPort
        private int port;

        @Autowired
        private WebTestClient webTestClient;

        @Autowired
        private OrderItemRepository orderItemRepository;

        @Autowired
        private ObjectMapper objectMapper;

        private ProductDto mockProductDto;
        private OrderDto mockOrderDto;
        private OrderItem testOrderItem;

        @BeforeEach
        void setUp() {
                // Configurar datos de prueba
                mockProductDto = ProductDto.builder()
                                .productId(1)
                                .productTitle("Laptop ASUS")
                                .imageUrl("laptop-image.jpg")
                                .sku("LAPTOP-001")
                                .priceUnit(999.99)
                                .quantity(25)
                                .build();

                mockOrderDto = OrderDto.builder()
                                .orderId(1)
                                .orderDate(LocalDateTime.now())
                                .orderDesc("Pedido de prueba")
                                .orderFee(1999.98)
                                .build();

                // Crear OrderItem en la base de datos
                testOrderItem = OrderItem.builder()
                                .productId(1)
                                .orderId(1)
                                .orderedQuantity(2)
                                .build();

                orderItemRepository.save(testOrderItem);
        }

        /**
         * Prueba de Integración #1: Validar comunicación exitosa con servicios externos
         * 
         * Esta prueba valida que el shipping service puede:
         * - Obtener todos los order items de la base de datos
         * - Comunicarse correctamente con product-service para obtener detalles del
         * producto
         * - Comunicarse correctamente con order-service para obtener detalles del
         * pedido
         * - Retornar la respuesta completa con toda la información integrada
         */
        @Test
        @DisplayName("Debe obtener todos los order items con detalles de producto y pedido")
        void shouldGetAllOrderItemsWithProductAndOrderDetails() throws Exception {
                // Given: Configurar mocks de servicios externos
                stubFor(get(urlMatching("/product-service/api/products/1"))
                                .willReturn(aResponse()
                                                .withStatus(200)
                                                .withHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                                                .withBody(objectMapper.writeValueAsString(mockProductDto))));

                stubFor(get(urlMatching("/order-service/api/orders/1"))
                                .willReturn(aResponse()
                                                .withStatus(200)
                                                .withHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                                                .withBody(objectMapper.writeValueAsString(mockOrderDto))));

                // When & Then: Realizar petición y validar respuesta
                webTestClient.get()
                                .uri("/shipping-service/api/shippings")
                                .accept(MediaType.APPLICATION_JSON)
                                .exchange()
                                .expectStatus().isOk()
                                .expectBody()
                                .jsonPath("$.collection").isArray()
                                .jsonPath("$.collection[0].productId").isEqualTo(1)
                                .jsonPath("$.collection[0].orderId").isEqualTo(1)
                                .jsonPath("$.collection[0].orderedQuantity").isEqualTo(2)
                                .jsonPath("$.collection[0].product.productTitle").isEqualTo("Laptop ASUS")
                                .jsonPath("$.collection[0].product.priceUnit").isEqualTo(999.99)
                                .jsonPath("$.collection[0].order.orderDesc").isEqualTo("Pedido de prueba")
                                .jsonPath("$.collection[0].order.orderFee").isEqualTo(1999.98);

                // Verificar que se llamaron los servicios externos
                verify(exactly(1), getRequestedFor(urlMatching("/product-service/api/products/1")));
                verify(exactly(1), getRequestedFor(urlMatching("/order-service/api/orders/1")));
        }

        /**
         * Prueba de Integración #2: Validar creación de order item y persistencia
         * 
         * Esta prueba valida que el shipping service puede:
         * - Recibir una petición POST con datos válidos
         * - Persistir el order item en la base de datos
         * - Retornar la respuesta correcta con los datos guardados
         * - Mantener la integridad de datos en la comunicación
         */
        @Test
        @DisplayName("Debe crear un nuevo order item correctamente")
        void shouldCreateNewOrderItemSuccessfully() throws Exception {
                // Given: Preparar datos para crear un nuevo order item
                OrderItemDto newOrderItemDto = OrderItemDto.builder()
                                .productId(2)
                                .orderId(2)
                                .orderedQuantity(3)
                                .build();

                // When & Then: Enviar petición POST y validar respuesta
                webTestClient.post()
                                .uri("/shipping-service/api/shippings")
                                .contentType(MediaType.APPLICATION_JSON)
                                .bodyValue(newOrderItemDto)
                                .exchange()
                                .expectStatus().isOk()
                                .expectBody()
                                .jsonPath("$.productId").isEqualTo(2)
                                .jsonPath("$.orderId").isEqualTo(2)
                                .jsonPath("$.orderedQuantity").isEqualTo(3);

                // Verificar que se persistió en la base de datos
                OrderItemId newOrderItemId = new OrderItemId(2, 2);
                assertTrue(orderItemRepository.findById(newOrderItemId).isPresent(),
                                "El nuevo order item debe estar persistido en la base de datos");

                OrderItem savedOrderItem = orderItemRepository.findById(newOrderItemId).get();
                assertThat(savedOrderItem.getOrderedQuantity()).isEqualTo(3);
        }

        /**
         * Prueba de Integración #3: Validar manejo de errores en comunicación con
         * servicios externos
         * 
         * Esta prueba valida que el shipping service puede:
         * - Manejar errores cuando los servicios externos no están disponibles
         * - Continuar funcionando cuando hay problemas de conectividad
         * - Retornar respuestas apropiadas en caso de fallo de servicios externos
         * - Mantener la estabilidad del sistema ante fallos parciales
         */
        @Test
        @DisplayName("Debe manejar errores de servicios externos correctamente")
        void shouldHandleExternalServiceErrorsGracefully() throws Exception {
                // Given: Configurar servicios externos para fallar
                stubFor(get(urlMatching("/product-service/api/products/1"))
                                .willReturn(aResponse()
                                                .withStatus(HttpStatus.INTERNAL_SERVER_ERROR.value())
                                                .withBody("Error interno del servidor")));

                stubFor(get(urlMatching("/order-service/api/orders/1"))
                                .willReturn(aResponse()
                                                .withStatus(HttpStatus.NOT_FOUND.value())
                                                .withBody("Order not found")));

                // When: Realizar petición que debe fallar por servicios externos
                webTestClient.get()
                                .uri("/shipping-service/api/shippings")
                                .accept(MediaType.APPLICATION_JSON)
                                .exchange()
                                .expectStatus().is5xxServerError(); // Esperamos error del servidor

                // Then: Verificar que se intentó llamar a los servicios externos
                verify(getRequestedFor(urlMatching("/product-service/api/products/1")));
                verify(getRequestedFor(urlMatching("/order-service/api/orders/1")));
        }

        /**
         * Prueba adicional: Validar eliminación de order item
         * 
         * Esta prueba complementaria valida:
         * - La eliminación correcta de order items
         * - La integridad referencial después de eliminar
         */
        @Test
        @DisplayName("Debe eliminar order item por ID compuesto")
        void shouldDeleteOrderItemByCompositeId() {
                // Given: Verificar que el order item existe
                OrderItemId orderItemId = new OrderItemId(1, 1);
                assertTrue(orderItemRepository.findById(orderItemId).isPresent());

                // When: Eliminar el order item
                webTestClient.delete()
                                .uri("/shipping-service/api/shippings/1/1")
                                .exchange()
                                .expectStatus().isOk()
                                .expectBody(Boolean.class)
                                .isEqualTo(true);

                // Then: Verificar que se eliminó de la base de datos
                assertFalse(orderItemRepository.findById(orderItemId).isPresent(),
                                "El order item debe haber sido eliminado de la base de datos");
        }
}

/**
 * Configuración de pruebas auxiliares para testing de integración
 */
class IntegrationTestConfig {

        /**
         * Configuración específica para WireMock y servicios externos
         * Esta clase puede extenderse para agregar más configuraciones de prueba
         */
        public static final String PRODUCT_SERVICE_BASE_URL = "/product-service/api/products";
        public static final String ORDER_SERVICE_BASE_URL = "/order-service/api/orders";

        /**
         * Datos de prueba estándar para reutilizar en múltiples tests
         */
        public static ProductDto createMockProduct(Integer productId, String title, Double price) {
                return ProductDto.builder()
                                .productId(productId)
                                .productTitle(title)
                                .priceUnit(price)
                                .quantity(50)
                                .sku("TEST-SKU-" + productId)
                                .build();
        }

        public static OrderDto createMockOrder(Integer orderId, String description, Double fee) {
                return OrderDto.builder()
                                .orderId(orderId)
                                .orderDesc(description)
                                .orderFee(fee)
                                .orderDate(LocalDateTime.now())
                                .build();
        }
}