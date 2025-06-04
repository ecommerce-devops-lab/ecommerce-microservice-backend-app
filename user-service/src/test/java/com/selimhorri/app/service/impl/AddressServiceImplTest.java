package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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

import com.selimhorri.app.domain.Address;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.exception.wrapper.AddressNotFoundException;
import com.selimhorri.app.helper.AddressMappingHelper;
import com.selimhorri.app.repository.AddressRepository;

@ExtendWith(MockitoExtension.class)
public class AddressServiceImplTest {

    @Mock
    private AddressRepository addressRepository;
    
    @InjectMocks
    private AddressServiceImpl addressService;
    
    private Address address1;
    private Address address2;
    private AddressDto addressDto1;
    private User user;
    
    @BeforeEach
    public void setup() {
        // Setup test data
        user = User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john@example.com")
                .phone("1234567890")
                .build();
        
        address1 = Address.builder()
                .addressId(1)
                .fullAddress("123 Main St")
                .postalCode("12345")
                .city("New York")
                .user(user)
                .build();
        
        address2 = Address.builder()
                .addressId(2)
                .fullAddress("456 Second Ave")
                .postalCode("67890")
                .city("Los Angeles")
                .user(user)
                .build();
        
        addressDto1 = AddressMappingHelper.map(address1);
    }
    
    @Test
    @DisplayName("Test findAll returns all addresses")
    public void testFindAll() {
        // Arrange
        when(addressRepository.findAll()).thenReturn(Arrays.asList(address1, address2));
        
        // Act
        List<AddressDto> addresses = addressService.findAll();
        
        // Assert
        assertEquals(2, addresses.size());
        verify(addressRepository, times(1)).findAll();
    }
    
    @Test
    @DisplayName("Test findById returns address when exists")
    public void testFindById_WhenAddressExists() {
        // Arrange
        when(addressRepository.findById(1)).thenReturn(Optional.of(address1));
        
        // Act
        AddressDto result = addressService.findById(1);
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getAddressId());
        assertEquals("123 Main St", result.getFullAddress());
        assertEquals("12345", result.getPostalCode());
        verify(addressRepository, times(1)).findById(1);
    }
    
    @Test
    @DisplayName("Test findById throws exception when address does not exist")
    public void testFindById_WhenAddressDoesNotExist() {
        // Arrange
        when(addressRepository.findById(anyInt())).thenReturn(Optional.empty());
        
        // Act & Assert
        assertThrows(AddressNotFoundException.class, () -> {
            addressService.findById(999);
        });
        
        verify(addressRepository, times(1)).findById(999);
    }
    
    @Test
    @DisplayName("Test save persists a new address")
    public void testSave() {
        // Arrange
        when(addressRepository.save(any(Address.class))).thenReturn(address1);
        
        // Act
        AddressDto result = addressService.save(addressDto1);
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getAddressId());
        assertEquals("123 Main St", result.getFullAddress());
        verify(addressRepository, times(1)).save(any(Address.class));
    }
      @Test
    @DisplayName("Test update modifies an existing address")
    public void testUpdate() {
        // Arrange
        // Modify the DTO and address object
        addressDto1.setFullAddress("123 Updated St");
        addressDto1.setCity("Chicago");
        
        // Create an updated address object that will be returned
        Address updatedAddress = Address.builder()
                .addressId(1)
                .fullAddress("123 Updated St")
                .postalCode("12345")
                .city("Chicago")
                .user(user)
                .build();
        
        when(addressRepository.save(any(Address.class))).thenReturn(updatedAddress);
        
        // Act
        AddressDto result = addressService.update(addressDto1);
        
        // Assert
        assertNotNull(result);
        assertEquals("123 Updated St", result.getFullAddress());
        assertEquals("Chicago", result.getCity());
        verify(addressRepository, times(1)).save(any(Address.class));
    }
}
