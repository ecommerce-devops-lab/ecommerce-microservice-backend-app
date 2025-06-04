package com.selimhorri.app.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;

@DataJpaTest
public class CredentialRepositoryTest {

    @Autowired
    private CredentialRepository credentialRepository;
    
    @Autowired
    private TestEntityManager entityManager;
    
    @Test
    @DisplayName("Test findByUsername when credential exists")
    public void testFindByUsername_WhenCredentialExists() {
        // Arrange
        String testUsername = "testuser";
        
        // Crear y persistir el usuario primero
        User user = User.builder()
                .firstName("Test")
                .lastName("User")
                .email("test@example.com")
                .phone("1234567890")
                .build();
        
        // Persistir el usuario primero
        entityManager.persist(user);
        
        // Crear y asociar las credenciales
        Credential credential = Credential.builder()
                .username(testUsername)
                .password("password")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .user(user)
                .build();
        
        // Establecer la relación bidireccional
        user.setCredential(credential);
        
        // Persistir las credenciales
        entityManager.persist(credential);
        entityManager.flush();
        
        // Act
        Optional<Credential> foundCredential = credentialRepository.findByUsername(testUsername);
        
        // Assert
        assertTrue(foundCredential.isPresent());
        assertEquals(testUsername, foundCredential.get().getUsername());
        assertEquals("password", foundCredential.get().getPassword());
        assertEquals(RoleBasedAuthority.ROLE_USER, foundCredential.get().getRoleBasedAuthority());
    }
    
    @Test
    @DisplayName("Test findByUsername when credential does not exist")
    public void testFindByUsername_WhenCredentialDoesNotExist() {
        // Act
        Optional<Credential> foundCredential = credentialRepository.findByUsername("nonexistentuser");
        
        // Assert
        assertTrue(foundCredential.isEmpty());
    }
}
