package com.selimhorri.app.resource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.config.MySQLTestContainerConfig;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(SpringExtension.class)
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers
@Import(MySQLTestContainerConfig.class)
@org.springframework.test.context.ContextConfiguration(initializers = MySQLTestContainerConfig.Initializer.class)
public class UserResourceIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;    @Test
    public void whenGetAllUsers_thenStatus200() throws Exception {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("test_user")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto user = UserDto.builder()
                .firstName("Test")
                .lastName("User")
                .email("test.user@example.com")
                .phone("1234567890")
                .build();
                
        // Configurar la relación evitando ciclos
        // credentialDto.setUserDto(user); <- Eliminamos esta línea para evitar ciclos
        user.setCredentialDto(credentialDto);
        
        userService.save(user);

        // When & Then
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data", hasSize(org.hamcrest.Matchers.greaterThanOrEqualTo(1))));
    }    @Test
    public void whenGetUserById_thenStatus200() throws Exception {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("john_doe")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto user = UserDto.builder()
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("9876543210")
                .build();
                
        // Configurar la relación evitando ciclos
        // credentialDto.setUserDto(user); <- Eliminamos esta línea para evitar ciclos
        user.setCredentialDto(credentialDto);
        
        UserDto savedUser = userService.save(user);

        // When & Then
        mockMvc.perform(get("/api/users/{userId}", savedUser.getUserId())
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.firstName", is("John")))
                .andExpect(jsonPath("$.data.lastName", is("Doe")));
    }@Test
    public void whenCreateUser_thenStatus201() throws Exception {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("jane_smith")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto user = UserDto.builder()
                .firstName("Jane")
                .lastName("Smith")
                .email("jane.smith@example.com")
                .phone("5555555555")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(user); <- Eliminamos esta línea para evitar ciclos
        user.setCredentialDto(credentialDto);

        // When & Then
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.firstName", is("Jane")))
                .andExpect(jsonPath("$.data.lastName", is("Smith")));
    }    @Test
    public void whenUpdateUser_thenStatus200() throws Exception {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("original_user")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto user = UserDto.builder()
                .firstName("Original")
                .lastName("User")
                .email("original.user@example.com")
                .phone("1112223333")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(user); <- Eliminamos esta línea para evitar ciclos
        user.setCredentialDto(credentialDto);
        
        UserDto savedUser = userService.save(user);
        
        savedUser.setFirstName("Updated");
        savedUser.setLastName("Person");
        
        // Evitamos configurar la relación inversa para evitar ciclos
        // savedUser.getCredentialDto().setUserDto(savedUser); <- Eliminamos esta línea

        // When & Then
        mockMvc.perform(put("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(savedUser)))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.data.firstName", is("Updated")))
                .andExpect(jsonPath("$.data.lastName", is("Person")));
    }@Test
    public void whenDeleteUser_thenStatus200() throws Exception {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("delete_me")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto user = UserDto.builder()
                .firstName("Delete")
                .lastName("Me")
                .email("delete.me@example.com")
                .phone("9998887777")
                .build();
                  // Configurar la relación evitando ciclos
        // credentialDto.setUserDto(user); <- Eliminamos esta línea para evitar ciclos
        user.setCredentialDto(credentialDto);
        
        UserDto savedUser = userService.save(user);

        // When & Then
        mockMvc.perform(delete("/api/users/{userId}", savedUser.getUserId())
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
        
        // Verify user is deleted
        mockMvc.perform(get("/api/users/{userId}", savedUser.getUserId())
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }
}
