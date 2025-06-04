package com.selimhorri.app.service;

import com.selimhorri.app.config.MySQLTestContainerConfig;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

@ExtendWith(SpringExtension.class)
@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
@Import(MySQLTestContainerConfig.class)
@org.springframework.test.context.ContextConfiguration(initializers = MySQLTestContainerConfig.Initializer.class)
public class UserServiceIntegrationTest {

    @Autowired
    private UserService userService;    
    
    @Test
    public void whenSaveUser_thenUserIsReturned() {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("alice_johnson")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
                
        UserDto userDto = UserDto.builder()
                .firstName("Alice")
                .lastName("Johnson")
                .email("alice.johnson@example.com")
                .phone("1122334455")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(userDto); <- Eliminamos esta línea para evitar ciclos
        userDto.setCredentialDto(credentialDto);

        // When
        UserDto savedUser = userService.save(userDto);

        // Then
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getUserId()).isNotNull();
        assertThat(savedUser.getFirstName()).isEqualTo("Alice");
        assertThat(savedUser.getLastName()).isEqualTo("Johnson");
    }
    
    @Test
    public void whenFindAllUsers_thenUsersAreReturned() {
        // Given
        CredentialDto credential1 = CredentialDto.builder()
                .username("bob_smith")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        UserDto user1 = UserDto.builder()
                .firstName("Bob")
                .lastName("Smith")
                .email("bob.smith@example.com")
                .phone("5566778899")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credential1.setUserDto(user1); <- eliminamos esta línea para evitar ciclos
        user1.setCredentialDto(credential1);

        CredentialDto credential2 = CredentialDto.builder()
                .username("charlie_brown")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        UserDto user2 = UserDto.builder()
                .firstName("Charlie")
                .lastName("Brown")
                .email("charlie.brown@example.com")
                .phone("9988776655")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credential2.setUserDto(user2); <- eliminamos esta línea para evitar ciclos
        user2.setCredentialDto(credential2);

        userService.save(user1);
        userService.save(user2);

        // When
        List<UserDto> users = userService.findAll();

        // Then
        assertThat(users).isNotEmpty();
        assertThat(users.size()).isGreaterThanOrEqualTo(2);
    }
    
    @Test
    public void whenFindUserById_thenUserIsReturned() {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("david_wilson")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        UserDto userDto = UserDto.builder()
                .firstName("David")
                .lastName("Wilson")
                .email("david.wilson@example.com")
                .phone("1231231234")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(userDto); <- Eliminamos esta línea para evitar ciclos
        userDto.setCredentialDto(credentialDto);

        UserDto savedUser = userService.save(userDto);

        // When
        UserDto foundUser = userService.findById(savedUser.getUserId());

        // Then
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getUserId()).isEqualTo(savedUser.getUserId());
        assertThat(foundUser.getFirstName()).isEqualTo("David");
    }

    @Test
    public void whenFindUserByInvalidId_thenThrowException() {
        // Given
        Integer invalidId = 9999;

        // When & Then
        assertThrows(UserObjectNotFoundException.class, () -> {
            userService.findById(invalidId);
        });
    }
    
    @Test
    public void whenUpdateUser_thenUserIsUpdated() {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("eva_davis")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        UserDto userDto = UserDto.builder()
                .firstName("Eva")
                .lastName("Davis")
                .email("eva.davis@example.com")
                .phone("3213214321")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(userDto); <- Eliminamos esta línea para evitar ciclos
        userDto.setCredentialDto(credentialDto);

        UserDto savedUser = userService.save(userDto);
        
        // When
        savedUser.setFirstName("Eve");
        savedUser.setPhone("9876543210");
        
        // Mantener la relación unidireccional para evitar ciclos
        // savedUser.getCredentialDto().setUserDto(savedUser); <- Eliminamos esta línea
        
        UserDto updatedUser = userService.update(savedUser);

        // Then
        assertThat(updatedUser).isNotNull();
        assertThat(updatedUser.getUserId()).isEqualTo(savedUser.getUserId());
        assertThat(updatedUser.getFirstName()).isEqualTo("Eve");
        assertThat(updatedUser.getPhone()).isEqualTo("9876543210");
    }
    
    @Test
    public void whenDeleteUser_thenUserIsRemoved() {
        // Given
        CredentialDto credentialDto = CredentialDto.builder()
                .username("frank_miller")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        
        UserDto userDto = UserDto.builder()
                .firstName("Frank")
                .lastName("Miller")
                .email("frank.miller@example.com")
                .phone("4564564567")
                .build();
                
        // Configurar la relación bidireccional evitando ciclos
        // credentialDto.setUserDto(userDto); <- Eliminamos esta línea para evitar ciclos
        userDto.setCredentialDto(credentialDto);

        UserDto savedUser = userService.save(userDto);
        
        // When
        userService.deleteById(savedUser.getUserId());
        
        // Then
        assertThrows(UserObjectNotFoundException.class, () -> {
            userService.findById(savedUser.getUserId());
        });
    }
}
