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

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.helper.UserMappingHelper;
import com.selimhorri.app.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
public class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private UserServiceImpl userService;
    
    private User user1;
    private User user2;
    private UserDto userDto1;
    
    @BeforeEach
    public void setup() {
        // Setup test data
        Credential credential1 = Credential.builder()
                .credentialId(1)
                .username("user1")
                .password("password1")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        user1 = User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john@example.com")
                .phone("1234567890")
                .credential(credential1)
                .build();
        
        credential1.setUser(user1);
        
        Credential credential2 = Credential.builder()
                .credentialId(2)
                .username("user2")
                .password("password2")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        user2 = User.builder()
                .userId(2)
                .firstName("Jane")
                .lastName("Smith")
                .email("jane@example.com")
                .phone("0987654321")
                .credential(credential2)
                .build();
        
        credential2.setUser(user2);
        
        userDto1 = UserMappingHelper.map(user1);
    }
    
    @Test
    @DisplayName("Test findAll returns all users")
    public void testFindAll() {
        // Arrange
        when(userRepository.findAll()).thenReturn(Arrays.asList(user1, user2));
        
        // Act
        List<UserDto> users = userService.findAll();
        
        // Assert
        assertEquals(2, users.size());
        verify(userRepository, times(1)).findAll();
    }
    
    @Test
    @DisplayName("Test findById returns user when exists")
    public void testFindById_WhenUserExists() {
        // Arrange
        when(userRepository.findById(1)).thenReturn(Optional.of(user1));
        
        // Act
        UserDto result = userService.findById(1);
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getUserId());
        assertEquals("John", result.getFirstName());
        assertEquals("john@example.com", result.getEmail());
        verify(userRepository, times(1)).findById(1);
    }
    
    @Test
    @DisplayName("Test findById throws exception when user does not exist")
    public void testFindById_WhenUserDoesNotExist() {
        // Arrange
        when(userRepository.findById(anyInt())).thenReturn(Optional.empty());
        
        // Act & Assert
        assertThrows(UserObjectNotFoundException.class, () -> {
            userService.findById(999);
        });
        
        verify(userRepository, times(1)).findById(999);
    }
    
    @Test
    @DisplayName("Test save persists a new user")
    public void testSave() {
        // Arrange
        when(userRepository.save(any(User.class))).thenReturn(user1);
        
        // Act
        UserDto result = userService.save(userDto1);
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getUserId());
        assertEquals("John", result.getFirstName());
        verify(userRepository, times(1)).save(any(User.class));
    }
      @Test
    @DisplayName("Test update modifies an existing user")
    public void testUpdate() {
        // Arrange
        // Modify the DTO
        userDto1.setFirstName("Johnny");
        userDto1.setEmail("johnny@example.com");
        
        // Create updated user to be returned by the mock
        User updatedUser = User.builder()
                .userId(1)
                .firstName("Johnny")
                .lastName("Doe")
                .email("johnny@example.com")
                .phone("1234567890")
                .credential(user1.getCredential())
                .build();
        
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);
        
        // Act
        UserDto result = userService.update(userDto1);
        
        // Assert
        assertNotNull(result);
        assertEquals("Johnny", result.getFirstName());
        assertEquals("johnny@example.com", result.getEmail());
        verify(userRepository, times(1)).save(any(User.class));
    }
    
    @Test
    @DisplayName("Test deleteById removes a user")
    public void testDeleteById() {
        // Arrange
        doNothing().when(userRepository).deleteById(anyInt());
        
        // Act
        userService.deleteById(1);
        
        // Assert
        verify(userRepository, times(1)).deleteById(1);
    }
    
    @Test
    @DisplayName("Test findByUsername returns user when exists")
    public void testFindByUsername_WhenUserExists() {
        // Arrange
        when(userRepository.findByCredentialUsername("user1")).thenReturn(Optional.of(user1));
        
        // Act
        UserDto result = userService.findByUsername("user1");
        
        // Assert
        assertNotNull(result);
        assertEquals(1, result.getUserId());
        assertEquals("John", result.getFirstName());
        assertEquals("john@example.com", result.getEmail());
        verify(userRepository, times(1)).findByCredentialUsername("user1");
    }
}
