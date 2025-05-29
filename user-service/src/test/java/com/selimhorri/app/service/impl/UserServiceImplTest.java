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

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserServiceImpl Unit Tests")
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserServiceImpl userService;

    private User mockUser;
    private UserDto mockUserDto;
    private Credential mockCredential;

    @BeforeEach
    void setUp() {
        mockCredential = Credential.builder()
                .credentialId(1)
                .username("testuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();

        mockUser = User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@test.com")
                .phone("+1234567890")
                .credential(mockCredential)
                .build();

        mockUserDto = UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@test.com")
                .phone("+1234567890")
                .credentialDto(CredentialDto.builder()
                        .credentialId(1)
                        .username("testuser")
                        .password("password123")
                        .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                        .isEnabled(true)
                        .isAccountNonExpired(true)
                        .isAccountNonLocked(true)
                        .isCredentialsNonExpired(true)
                        .build())
                .build();
    }

    @Test
    @DisplayName("Should return all users when findAll is called")
    void shouldReturnAllUsers() {
        // Given
        List<User> users = Arrays.asList(mockUser);
        when(userRepository.findAll()).thenReturn(users);

        // When
        List<UserDto> result = userService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("John", result.get(0).getFirstName());
        assertEquals("Doe", result.get(0).getLastName());
        verify(userRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("Should return user when valid ID is provided")
    void shouldReturnUserById() {
        // Given
        when(userRepository.findById(1)).thenReturn(Optional.of(mockUser));

        // When
        UserDto result = userService.findById(1);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getUserId());
        assertEquals("John", result.getFirstName());
        assertEquals("testuser", result.getCredentialDto().getUsername());
        verify(userRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("Should throw UserObjectNotFoundException when user not found")
    void shouldThrowExceptionWhenUserNotFound() {
        // Given
        when(userRepository.findById(anyInt())).thenReturn(Optional.empty());

        // When & Then
        UserObjectNotFoundException exception = assertThrows(
            UserObjectNotFoundException.class,
            () -> userService.findById(999)
        );
        
        assertTrue(exception.getMessage().contains("User with id: 999 not found"));
        verify(userRepository, times(1)).findById(999);
    }

    @Test
    @DisplayName("Should save user successfully")
    void shouldSaveUserSuccessfully() {
        // Given
        when(userRepository.save(any(User.class))).thenReturn(mockUser);

        // When
        UserDto result = userService.save(mockUserDto);

        // Then
        assertNotNull(result);
        assertEquals("John", result.getFirstName());
        assertEquals("Doe", result.getLastName());
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    @DisplayName("Should find user by username successfully")
    void shouldFindUserByUsername() {
        // Given
        when(userRepository.findByCredentialUsername("testuser"))
                .thenReturn(Optional.of(mockUser));

        // When
        UserDto result = userService.findByUsername("testuser");

        // Then
        assertNotNull(result);
        assertEquals("testuser", result.getCredentialDto().getUsername());
        assertEquals("John", result.getFirstName());
        verify(userRepository, times(1)).findByCredentialUsername("testuser");
    }
}