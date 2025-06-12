package com.selimhorri.app.helper;

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;

public interface PaymentMappingHelper {

	public static PaymentDto map(final Payment payment) {
		return PaymentDto.builder()
				.paymentId(payment.getPaymentId())
				.isPayed(payment.getIsPayed())
				.paymentStatus(payment.getPaymentStatus())
				.orderDto(payment.getOrderId() != null ? OrderDto.builder()
						.orderId(payment.getOrderId())
						.build() : null)
				.build();
	}

	public static Payment map(final PaymentDto paymentDto) {
		return Payment.builder()
				.paymentId(paymentDto.getPaymentId())
				.orderId(paymentDto.getOrderDto().getOrderId())
				.isPayed(paymentDto.getIsPayed())
				.paymentStatus(paymentDto.getPaymentStatus())
				.build();
	}

}