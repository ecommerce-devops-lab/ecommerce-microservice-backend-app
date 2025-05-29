package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.OrderItemNotFoundException;
import com.selimhorri.app.repository.OrderItemRepository;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderItemServiceImpl Unit Tests")
class OrderItemServiceImplTest {

    @Mock
    private OrderItemRepository orderItemRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private OrderItemServiceImpl orderItemService;

    private OrderItem mockOrderItem;
    private OrderItemDto mockOrderItemDto;
    private OrderItemId mockOrderItemId;
    private ProductDto mockProductDto;
    private OrderDto mockOrderDto;

    @BeforeEach
    void setUp() {
        mockOrderItemId = new OrderItemId(1, 1);

        mockProductDto = ProductDto.builder()
                .productId(1)
                .productTitle("Test Product")
                .imageUrl("product-image.jpg")
                .sku("TEST-SKU-001")
                .priceUnit(99.99)
                .quantity(50)
                .build();

        mockOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(199.98)
                .build();

        mockOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(2)
                .build();

        mockOrderItemDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(2)
                .productDto(ProductDto.builder()
                        .productId(1)
                        .build())
                .orderDto(OrderDto.builder()
                        .orderId(1)
                        .build())
                .build();
    }

    @Test
    @DisplayName("Should return all order items with product and order details")
    void shouldReturnAllOrderItemsWithDetails() {
        // Given
        List<OrderItem> orderItems = Arrays.asList(mockOrderItem);
        when(orderItemRepository.findAll()).thenReturn(orderItems);
        when(restTemplate.getForObject(contains("/products/1"), eq(ProductDto.class)))
                .thenReturn(mockProductDto);
        when(restTemplate.getForObject(contains("/orders/1"), eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // When
        List<OrderItemDto> result = orderItemService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(2, result.get(0).getOrderedQuantity());
        assertNotNull(result.get(0).getProductDto());
        assertNotNull(result.get(0).getOrderDto());
        assertEquals("Test Product", result.get(0).getProductDto().getProductTitle());
        assertEquals("Test Order", result.get(0).getOrderDto().getOrderDesc());
        verify(orderItemRepository, times(1)).findAll();
        verify(restTemplate, times(1)).getForObject(contains("/products/1"), eq(ProductDto.class));
        verify(restTemplate, times(1)).getForObject(contains("/orders/1"), eq(OrderDto.class));
    }

    @Test
    @DisplayName("Should save order item successfully")
    void shouldSaveOrderItemSuccessfully() {
        // Given
        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(mockOrderItem);

        // When
        OrderItemDto result = orderItemService.save(mockOrderItemDto);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getProductId());
        assertEquals(1, result.getOrderId());
        assertEquals(2, result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    @Test
    @DisplayName("Should update order item successfully")
    void shouldUpdateOrderItemSuccessfully() {
        // Given
        OrderItem updatedOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .build();

        OrderItemDto updatedOrderItemDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .productDto(ProductDto.builder()
                        .productId(1)
                        .build())
                .orderDto(OrderDto.builder()
                        .orderId(1)
                        .build())
                .build();

        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(updatedOrderItem);

        // When
        OrderItemDto result = orderItemService.update(updatedOrderItemDto);

        // Then
        assertNotNull(result);
        assertEquals(5, result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    @Test
    @DisplayName("Should delete order item by composite ID successfully")
    void shouldDeleteOrderItemByIdSuccessfully() {
        // Given
        doNothing().when(orderItemRepository).deleteById(mockOrderItemId);

        // When
        orderItemService.deleteById(mockOrderItemId);

        // Then
        verify(orderItemRepository, times(1)).deleteById(mockOrderItemId);
    }

    @Test
    @DisplayName("Should validate ordered quantity is positive")
    void shouldValidateOrderedQuantityIsPositive() {
        // Given
        OrderItem validOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(3)
                .build();

        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(validOrderItem);

        OrderItemDto orderItemDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(3)
                .build();

        // When
        OrderItemDto result = orderItemService.save(orderItemDto);

        // Then
        assertNotNull(result);
        assertTrue(result.getOrderedQuantity() > 0, "Ordered quantity should be positive");
        assertEquals(3, result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    @Test
    @DisplayName("Should handle external service integration correctly")
    void shouldHandleExternalServiceIntegration() {
        // Given
        List<OrderItem> orderItems = Arrays.asList(mockOrderItem);
        when(orderItemRepository.findAll()).thenReturn(orderItems);
        when(restTemplate.getForObject(anyString(), eq(ProductDto.class)))
                .thenReturn(mockProductDto);
        when(restTemplate.getForObject(anyString(), eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // When
        List<OrderItemDto> result = orderItemService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        
        OrderItemDto orderItemDto = result.get(0);
        assertNotNull(orderItemDto.getProductDto());
        assertNotNull(orderItemDto.getOrderDto());
        
        // Verify external service calls
        verify(restTemplate, times(1)).getForObject(anyString(), eq(ProductDto.class));
        verify(restTemplate, times(1)).getForObject(anyString(), eq(OrderDto.class));
        
        // Verify data integrity
        assertEquals(mockProductDto.getProductTitle(), orderItemDto.getProductDto().getProductTitle());
        assertEquals(mockOrderDto.getOrderDesc(), orderItemDto.getOrderDto().getOrderDesc());
    }
}