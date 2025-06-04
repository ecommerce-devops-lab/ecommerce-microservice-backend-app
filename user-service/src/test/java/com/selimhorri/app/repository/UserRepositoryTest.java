package com.selimhorri.app.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;

@DataJpaTest
public class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private CredentialRepository credentialRepository;
    
    @Test
    @DisplayName("Test findByCredentialUsername when user exists")
    public void testFindByCredentialUsername_WhenUserExists() {
        // Arrange
        String testUsername = "testuser";
        
        // Create credential
        Credential credential = Credential.builder()
                .username(testUsername)
                .password("password")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        // Create user
        User user = User.builder()
                .firstName("Test")
                .lastName("User")
                .email("test@example.com")
                .phone("1234567890")
                .credential(credential)
                .build();
        
        credential.setUser(user);
        
        // Save user (which will cascade to credential)
        userRepository.save(user);
        
        // Act
        Optional<User> foundUser = userRepository.findByCredentialUsername(testUsername);
        
        // Assert
        assertTrue(foundUser.isPresent());
        assertEquals("Test", foundUser.get().getFirstName());
        assertEquals("User", foundUser.get().getLastName());
        assertEquals("test@example.com", foundUser.get().getEmail());
    }
    
    @Test
    @DisplayName("Test findByCredentialUsername when user does not exist")
    public void testFindByCredentialUsername_WhenUserDoesNotExist() {
        // Act
        Optional<User> foundUser = userRepository.findByCredentialUsername("nonexistentuser");
        
        // Assert
        assertTrue(foundUser.isEmpty());
    }
}
