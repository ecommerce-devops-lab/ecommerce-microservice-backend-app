package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

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

import com.selimhorri.app.domain.Category;
import com.selimhorri.app.domain.Product;
import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;
import com.selimhorri.app.repository.ProductRepository;

@ExtendWith(MockitoExtension.class)
@DisplayName("ProductServiceImpl Unit Tests")
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private Product mockProduct;
    private ProductDto mockProductDto;
    private Category mockCategory;

    @BeforeEach
    void setUp() {
        mockCategory = Category.builder()
                .categoryId(1)
                .categoryTitle("Electronics")
                .imageUrl("category-image.jpg")
                .build();

        mockProduct = Product.builder()
                .productId(1)
                .productTitle("Test Product")
                .imageUrl("product-image.jpg")
                .sku("TEST-SKU-001")
                .priceUnit(99.99)
                .quantity(50)
                .category(mockCategory)
                .build();

        mockProductDto = ProductDto.builder()
                .productId(1)
                .productTitle("Test Product")
                .imageUrl("product-image.jpg")
                .sku("TEST-SKU-001")
                .priceUnit(99.99)
                .quantity(50)
                .categoryDto(CategoryDto.builder()
                        .categoryId(1)
                        .categoryTitle("Electronics")
                        .imageUrl("category-image.jpg")
                        .build())
                .build();
    }

    @Test
    @DisplayName("Should return all products when findAll is called")
    void shouldReturnAllProducts() {
        // Given
        List<Product> products = Arrays.asList(mockProduct);
        when(productRepository.findAll()).thenReturn(products);

        // When
        List<ProductDto> result = productService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Test Product", result.get(0).getProductTitle());
        assertEquals("TEST-SKU-001", result.get(0).getSku());
        assertEquals(99.99, result.get(0).getPriceUnit());
        assertEquals(50, result.get(0).getQuantity());
        assertEquals("Electronics", result.get(0).getCategoryDto().getCategoryTitle());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should return product when valid ID is provided")
    void shouldReturnProductById() {
        // Given
        when(productRepository.findById(1)).thenReturn(Optional.of(mockProduct));

        // When
        ProductDto result = productService.findById(1);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getProductId());
        assertEquals("Test Product", result.getProductTitle());
        assertEquals("TEST-SKU-001", result.getSku());
        assertEquals(99.99, result.getPriceUnit());
        assertEquals(50, result.getQuantity());
        assertNotNull(result.getCategoryDto());
        assertEquals("Electronics", result.getCategoryDto().getCategoryTitle());
        verify(productRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("Should throw ProductNotFoundException when product not found")
    void shouldThrowExceptionWhenProductNotFound() {
        // Given
        when(productRepository.findById(anyInt())).thenReturn(Optional.empty());

        // When & Then
        ProductNotFoundException exception = assertThrows(
            ProductNotFoundException.class,
            () -> productService.findById(999)
        );
        
        assertTrue(exception.getMessage().contains("Product with id: 999 not found"));
        verify(productRepository, times(1)).findById(999);
    }

    @Test
    @DisplayName("Should save product successfully")
    void shouldSaveProductSuccessfully() {
        // Given
        when(productRepository.save(any(Product.class))).thenReturn(mockProduct);

        // When
        ProductDto result = productService.save(mockProductDto);

        // Then
        assertNotNull(result);
        assertEquals("Test Product", result.getProductTitle());
        assertEquals("TEST-SKU-001", result.getSku());
        assertEquals(99.99, result.getPriceUnit());
        assertEquals(50, result.getQuantity());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    @DisplayName("Should update product successfully")
    void shouldUpdateProductSuccessfully() {
        // Given
        Product updatedProduct = Product.builder()
                .productId(1)
                .productTitle("Updated Product")
                .imageUrl("updated-image.jpg")
                .sku("UPDATED-SKU-001")
                .priceUnit(149.99)
                .quantity(30)
                .category(mockCategory)
                .build();

        ProductDto updatedProductDto = ProductDto.builder()
                .productId(1)
                .productTitle("Updated Product")
                .imageUrl("updated-image.jpg")
                .sku("UPDATED-SKU-001")
                .priceUnit(149.99)
                .quantity(30)
                .categoryDto(CategoryDto.builder()
                        .categoryId(1)
                        .categoryTitle("Electronics")
                        .imageUrl("category-image.jpg")
                        .build())
                .build();

        when(productRepository.save(any(Product.class))).thenReturn(updatedProduct);

        // When
        ProductDto result = productService.update(updatedProductDto);

        // Then
        assertNotNull(result);
        assertEquals("Updated Product", result.getProductTitle());
        assertEquals("UPDATED-SKU-001", result.getSku());
        assertEquals(149.99, result.getPriceUnit());
        assertEquals(30, result.getQuantity());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    @DisplayName("Should delete product by ID successfully")
    void shouldDeleteProductByIdSuccessfully() {
        // Given
        when(productRepository.findById(1)).thenReturn(Optional.of(mockProduct));
        doNothing().when(productRepository).delete(any(Product.class));

        // When
        productService.deleteById(1);

        // Then
        verify(productRepository, times(1)).findById(1);
        verify(productRepository, times(1)).delete(any(Product.class));
    }

    @Test
    @DisplayName("Should validate product stock quantity")
    void shouldValidateProductStockQuantity() {
        // Given
        Product lowStockProduct = Product.builder()
                .productId(2)
                .productTitle("Low Stock Product")
                .quantity(5)
                .priceUnit(25.0)
                .category(mockCategory)
                .build();

        when(productRepository.findById(2)).thenReturn(Optional.of(lowStockProduct));

        // When
        ProductDto result = productService.findById(2);

        // Then
        assertNotNull(result);
        assertEquals(5, result.getQuantity());
        assertTrue(result.getQuantity() < 10, "Product should have low stock");
        verify(productRepository, times(1)).findById(2);
    }
}