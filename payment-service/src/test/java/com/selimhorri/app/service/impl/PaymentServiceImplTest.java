package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
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

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.domain.PaymentStatus;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.exception.wrapper.PaymentNotFoundException;
import com.selimhorri.app.repository.PaymentRepository;

@ExtendWith(MockitoExtension.class)
@DisplayName("PaymentServiceImpl Unit Tests")
class PaymentServiceImplTest {

    @Mock
    private PaymentRepository paymentRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private PaymentServiceImpl paymentService;

    private Payment mockPayment;
    private PaymentDto mockPaymentDto;
    private OrderDto mockOrderDto;

    @BeforeEach
    void setUp() {
        mockOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(99.99)
                .build();

        mockPayment = Payment.builder()
                .paymentId(1)
                .orderId(1)
                .isPayed(false)
                .paymentStatus(PaymentStatus.IN_PROGRESS)
                .build();

        mockPaymentDto = PaymentDto.builder()
                .paymentId(1)
                .isPayed(false)
                .paymentStatus(PaymentStatus.IN_PROGRESS)
                .orderDto(OrderDto.builder()
                        .orderId(1)
                        .build())
                .build();
    }

    @Test
    @DisplayName("Should return all payments with order details")
    void shouldReturnAllPaymentsWithOrderDetails() {
        // Given
        List<Payment> payments = Arrays.asList(mockPayment);
        when(paymentRepository.findAll()).thenReturn(payments);
        when(restTemplate.getForObject(anyString(), eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // When
        List<PaymentDto> result = paymentService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(PaymentStatus.IN_PROGRESS, result.get(0).getPaymentStatus());
        assertFalse(result.get(0).getIsPayed());
        assertNotNull(result.get(0).getOrderDto());
        assertEquals("Test Order", result.get(0).getOrderDto().getOrderDesc());
        verify(paymentRepository, times(1)).findAll();
        verify(restTemplate, times(1)).getForObject(anyString(), eq(OrderDto.class));
    }

    @Test
    @DisplayName("Should return payment by ID with order details")
    void shouldReturnPaymentByIdWithOrderDetails() {
        // Given
        when(paymentRepository.findById(1)).thenReturn(Optional.of(mockPayment));
        when(restTemplate.getForObject(anyString(), eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // When
        PaymentDto result = paymentService.findById(1);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getPaymentId());
        assertEquals(PaymentStatus.IN_PROGRESS, result.getPaymentStatus());
        assertFalse(result.getIsPayed());
        assertNotNull(result.getOrderDto());
        assertEquals("Test Order", result.getOrderDto().getOrderDesc());
        verify(paymentRepository, times(1)).findById(1);
        verify(restTemplate, times(1)).getForObject(anyString(), eq(OrderDto.class));
    }

    @Test
    @DisplayName("Should throw PaymentNotFoundException when payment not found")
    void shouldThrowExceptionWhenPaymentNotFound() {
        // Given
        when(paymentRepository.findById(anyInt())).thenReturn(Optional.empty());

        // When & Then
        PaymentNotFoundException exception = assertThrows(
            PaymentNotFoundException.class,
            () -> paymentService.findById(999)
        );
        
        assertTrue(exception.getMessage().contains("Payment with id: 999 not found"));
        verify(paymentRepository, times(1)).findById(999);
        verifyNoInteractions(restTemplate);
    }

    @Test
    @DisplayName("Should save payment successfully")
    void shouldSavePaymentSuccessfully() {
        // Given
        when(paymentRepository.save(any(Payment.class))).thenReturn(mockPayment);

        // When
        PaymentDto result = paymentService.save(mockPaymentDto);

        // Then
        assertNotNull(result);
        assertEquals(PaymentStatus.IN_PROGRESS, result.getPaymentStatus());
        assertFalse(result.getIsPayed());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }

    @Test
    @DisplayName("Should update payment successfully")
    void shouldUpdatePaymentSuccessfully() {
        // Given
        Payment updatedPayment = Payment.builder()
                .paymentId(1)
                .orderId(1)
                .isPayed(true)
                .paymentStatus(PaymentStatus.COMPLETED)
                .build();

        PaymentDto updatedPaymentDto = PaymentDto.builder()
                .paymentId(1)
                .isPayed(true)
                .paymentStatus(PaymentStatus.COMPLETED)
                .orderDto(OrderDto.builder()
                        .orderId(1)
                        .build())
                .build();

        when(paymentRepository.save(any(Payment.class))).thenReturn(updatedPayment);

        // When
        PaymentDto result = paymentService.update(updatedPaymentDto);

        // Then
        assertNotNull(result);
        assertEquals(PaymentStatus.COMPLETED, result.getPaymentStatus());
        assertTrue(result.getIsPayed());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }

    @Test
    @DisplayName("Should delete payment by ID successfully")
    void shouldDeletePaymentByIdSuccessfully() {
        // Given
        doNothing().when(paymentRepository).deleteById(1);

        // When
        paymentService.deleteById(1);

        // Then
        verify(paymentRepository, times(1)).deleteById(1);
    }
}