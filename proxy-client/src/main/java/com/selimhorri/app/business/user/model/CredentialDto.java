package com.selimhorri.app.business.user.model;

import java.util.Set;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class CredentialDto {
	
	private Integer credentialId;
	private String username;
	private String password;
	private Role role;
	private Boolean isEnabled;
	private Boolean isAccountNonExpired;
	private Boolean isAccountNonLocked;
	private Boolean isCredentialsNonExpired;
	
	@JsonInclude(value = Include.NON_NULL)
	private UserDto user;
	
	@JsonInclude(value = Include.NON_NULL)
	private Set<VerificationTokenDto> verificationTokenDtos;
	
}







