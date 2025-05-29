package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
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

import com.selimhorri.app.domain.Cart;
import com.selimhorri.app.domain.Order;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.exception.wrapper.OrderNotFoundException;
import com.selimhorri.app.repository.OrderRepository;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderServiceImpl Unit Tests")
class OrderServiceImplTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private Order mockOrder;
    private OrderDto mockOrderDto;
    private Cart mockCart;

    @BeforeEach
    void setUp() {
        mockCart = Cart.builder()
                .cartId(1)
                .userId(1)
                .build();

        mockOrder = Order.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(99.99)
                .cart(mockCart)
                .build();

        mockOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(99.99)
                .cartDto(CartDto.builder()
                        .cartId(1)
                        .userId(1)
                        .build())
                .build();
    }

    @Test
    @DisplayName("Should return all orders when findAll is called")
    void shouldReturnAllOrders() {
        // Given
        List<Order> orders = Arrays.asList(mockOrder);
        when(orderRepository.findAll()).thenReturn(orders);

        // When
        List<OrderDto> result = orderService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Test Order", result.get(0).getOrderDesc());
        assertEquals(99.99, result.get(0).getOrderFee());
        verify(orderRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should return order when valid ID is provided")
    void shouldReturnOrderById() {
        // Given
        when(orderRepository.findById(1)).thenReturn(Optional.of(mockOrder));

        // When
        OrderDto result = orderService.findById(1);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getOrderId());
        assertEquals("Test Order", result.getOrderDesc());
        assertEquals(99.99, result.getOrderFee());
        assertEquals(1, result.getCartDto().getCartId());
        verify(orderRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("Should throw OrderNotFoundException when order not found")
    void shouldThrowExceptionWhenOrderNotFound() {
        // Given
        when(orderRepository.findById(anyInt())).thenReturn(Optional.empty());

        // When & Then
        OrderNotFoundException exception = assertThrows(
            OrderNotFoundException.class,
            () -> orderService.findById(999)
        );
        
        assertTrue(exception.getMessage().contains("Order with id: 999 not found"));
        verify(orderRepository, times(1)).findById(999);
    }

    @Test
    @DisplayName("Should save order successfully")
    void shouldSaveOrderSuccessfully() {
        // Given
        when(orderRepository.save(any(Order.class))).thenReturn(mockOrder);

        // When
        OrderDto result = orderService.save(mockOrderDto);

        // Then
        assertNotNull(result);
        assertEquals("Test Order", result.getOrderDesc());
        assertEquals(99.99, result.getOrderFee());
        verify(orderRepository, times(1)).save(any(Order.class));
    }

    @Test
    @DisplayName("Should update order successfully")
    void shouldUpdateOrderSuccessfully() {
        // Given
        Order updatedOrder = Order.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Updated Order")
                .orderFee(149.99)
                .cart(mockCart)
                .build();

        OrderDto updatedOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Updated Order")
                .orderFee(149.99)
                .cartDto(CartDto.builder()
                        .cartId(1)
                        .userId(1)
                        .build())
                .build();

        when(orderRepository.save(any(Order.class))).thenReturn(updatedOrder);

        // When
        OrderDto result = orderService.update(updatedOrderDto);

        // Then
        assertNotNull(result);
        assertEquals("Updated Order", result.getOrderDesc());
        assertEquals(149.99, result.getOrderFee());
        verify(orderRepository, times(1)).save(any(Order.class));
    }

    @Test
    @DisplayName("Should delete order by ID successfully")
    void shouldDeleteOrderByIdSuccessfully() {
        // Given
        when(orderRepository.findById(1)).thenReturn(Optional.of(mockOrder));
        doNothing().when(orderRepository).delete(any(Order.class));

        // When
        orderService.deleteById(1);

        // Then
        verify(orderRepository, times(1)).findById(1);
        verify(orderRepository, times(1)).delete(any(Order.class));
    }
}