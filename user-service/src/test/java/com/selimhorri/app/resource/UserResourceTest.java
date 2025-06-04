package com.selimhorri.app.resource;

import static org.hamcrest.CoreMatchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.service.UserService;

@WebMvcTest(UserResource.class)
public class UserResourceTest {

    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @MockBean
    private UserService userService;
    
    private UserDto userDto1;
    private UserDto userDto2;
    
    @BeforeEach
    public void setup() {
        // Setup test data
        CredentialDto credentialDto1 = CredentialDto.builder()
                .credentialId(1)
                .username("user1")
                .password("password1")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        userDto1 = UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john@example.com")
                .phone("1234567890")
                .credentialDto(credentialDto1)
                .build();
        
        CredentialDto credentialDto2 = CredentialDto.builder()
                .credentialId(2)
                .username("user2")
                .password("password2")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        userDto2 = UserDto.builder()
                .userId(2)
                .firstName("Jane")
                .lastName("Smith")
                .email("jane@example.com")
                .phone("0987654321")
                .credentialDto(credentialDto2)
                .build();
    }
      @Test
    @DisplayName("Test findAll endpoint returns all users")
    public void testFindAll() throws Exception {
        // Arrange
        List<UserDto> userDtos = Arrays.asList(userDto1, userDto2);
        when(userService.findAll()).thenReturn(userDtos);
        
        // Act & Assert
        mockMvc.perform(get("/api/users"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.size()", is(2)))
            .andExpect(jsonPath("$.data[0].userId", is(1)))
            .andExpect(jsonPath("$.data[0].firstName", is("John")))
            .andExpect(jsonPath("$.data[1].userId", is(2)))
            .andExpect(jsonPath("$.data[1].firstName", is("Jane")));
    }
      @Test
    @DisplayName("Test findById endpoint returns user when exists")
    public void testFindById() throws Exception {
        // Arrange
        when(userService.findById(1)).thenReturn(userDto1);
        
        // Act & Assert
        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.userId", is(1)))
            .andExpect(jsonPath("$.data.firstName", is("John")))
            .andExpect(jsonPath("$.data.email", is("john@example.com")));
    }
      @Test
    @DisplayName("Test save endpoint creates a new user")
    public void testSave() throws Exception {
        // Arrange
        when(userService.save(any(UserDto.class))).thenReturn(userDto1);
        
        // Act & Assert
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(userDto1)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.data.userId", is(1)))
            .andExpect(jsonPath("$.data.firstName", is("John")))
            .andExpect(jsonPath("$.data.email", is("john@example.com")));
    }
      @Test
    @DisplayName("Test update endpoint modifies an existing user")
    public void testUpdate() throws Exception {
        // Arrange
        when(userService.update(any(UserDto.class))).thenReturn(userDto1);
        
        // Act & Assert
        mockMvc.perform(put("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(userDto1)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.userId", is(1)))
            .andExpect(jsonPath("$.data.firstName", is("John")));
    }
      @Test
    @DisplayName("Test delete endpoint removes a user")
    public void testDeleteById() throws Exception {
        // Arrange
        doNothing().when(userService).deleteById(anyInt());
        
        // Act & Assert
        mockMvc.perform(delete("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data", is(true)));
    }
}
