package com.selimhorri.app.resource;

import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.dto.response.DtoResponse;
import com.selimhorri.app.dto.response.collection.DtoCollectionResponse;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.service.UserService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping(value = {"/api/users"})
@Slf4j
@RequiredArgsConstructor
public class UserResource {
	
	private final UserService userService;
	
	@GetMapping
	public ResponseEntity<DtoCollectionResponse<UserDto>> findAll() {
		log.info("*** UserDto List, controller; fetch all users *");
		return ResponseEntity.ok(new DtoCollectionResponse<>(this.userService.findAll()));
	}
		@GetMapping("/{userId}")
	public ResponseEntity<DtoResponse<UserDto>> findById(
			@PathVariable("userId") 
			@NotBlank(message = "Input must not blank") 
			@Valid final String userId) {
		log.info("*** UserDto, resource; fetch user by id *");
		try {
			return ResponseEntity.ok(new DtoResponse<>(this.userService.findById(Integer.parseInt(userId.strip()))));
		} catch (UserObjectNotFoundException ex) {
			log.error("User not found with id: {}", userId);
			return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
		}
	}
	
	@PostMapping
	public ResponseEntity<DtoResponse<UserDto>> save(
			@RequestBody 
			@NotNull(message = "Input must not NULL") 
			@Valid final UserDto userDto) {
		log.info("*** UserDto, resource; save user *");
		return ResponseEntity.status(HttpStatus.CREATED).body(new DtoResponse<>(this.userService.save(userDto)));
	}
	
	@PutMapping
	public ResponseEntity<DtoResponse<UserDto>> update(
			@RequestBody 
			@NotNull(message = "Input must not NULL") 
			@Valid final UserDto userDto) {
		log.info("*** UserDto, resource; update user *");
		return ResponseEntity.ok(new DtoResponse<>(this.userService.update(userDto)));
	}
	
	@PutMapping("/{userId}")
	public ResponseEntity<DtoResponse<UserDto>> update(
			@PathVariable("userId") 
			@NotBlank(message = "Input must not blank") final String userId, 
			@RequestBody 
			@NotNull(message = "Input must not NULL") 
			@Valid final UserDto userDto) {
		log.info("*** UserDto, resource; update user with userId *");
		return ResponseEntity.ok(new DtoResponse<>(this.userService.update(Integer.parseInt(userId.strip()), userDto)));
	}
	
	@DeleteMapping("/{userId}")
	public ResponseEntity<DtoResponse<Boolean>> deleteById(@PathVariable("userId") @NotBlank(message = "Input must not blank") @Valid final String userId) {
		log.info("*** Boolean, resource; delete user by id *");
		this.userService.deleteById(Integer.parseInt(userId.strip()));
		return ResponseEntity.ok(new DtoResponse<>(true));
	}
	
	@GetMapping("/username/{username}")
	public ResponseEntity<DtoResponse<UserDto>> findByUsername(
			@PathVariable("username") 
			@NotBlank(message = "Input must not blank") 
			@Valid final String username) {
		return ResponseEntity.ok(new DtoResponse<>(this.userService.findByUsername(username)));
	}
	
}
