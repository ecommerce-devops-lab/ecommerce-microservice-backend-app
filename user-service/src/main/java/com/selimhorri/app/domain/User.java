package com.selimhorri.app.domain;

import java.io.Serializable;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;
import javax.validation.constraints.Email;

import com.fasterxml.jackson.annotation.JsonIgnore;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * Represents a user entity in the e-commerce system.
 * <p>
 * This class is mapped to the "users" table in the database and serves as the
 * central entity for user management. It contains personal information about users
 * and maintains relationships with other entities like addresses and credentials.
 * </p>
 * <p>
 * The class implements {@link Serializable} for object serialization and extends
 * {@link AbstractMappedEntity} to inherit common entity attributes.
 * </p>
 * 
 * @author ecommerce-microservice-team
 * @version 1.0
 * @since 2025-05-28
 */
@Entity
@Table(name = "users")
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true, exclude = {"addresses", "credential"})
@Data
@Builder
public final class User extends AbstractMappedEntity implements Serializable {
	
	/** Serial Version UID for serialization */
	private static final long serialVersionUID = 1L;
	
	/**
	 * Primary key for the user entity.
	 * Auto-generated unique identifier that cannot be updated after creation.
	 */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_id", unique = true, nullable = false, updatable = false)
	private Integer userId;
	
	/**
	 * The user's first name.
	 */
	@Column(name = "first_name")
	private String firstName;
	
	/**
	 * The user's last name.
	 */
	@Column(name = "last_name")
	private String lastName;
	
	/**
	 * URL to the user's profile image.
	 */
	@Column(name = "image_url")
	private String imageUrl;
	
	/**
	 * The user's email address.
	 * Must be in a valid email format.
	 */
	@Email(message = "*Input must be in Email format!**")
	private String email;
	
	/**
	 * The user's phone number.
	 */
	private String phone;
	
	/**
	 * Collection of addresses associated with this user.
	 * This is a bidirectional relationship with {@link Address} entity.
	 * The addresses are lazily fetched and will cascade all operations.
	 */
	@JsonIgnore
	@OneToMany(cascade = CascadeType.ALL, mappedBy = "user", fetch = FetchType.LAZY)
	private Set<Address> addresses;
	
	/**
	 * The user's credential information.
	 * This is a bidirectional one-to-one relationship with {@link Credential} entity.
	 * The credential is lazily fetched and will cascade all operations.
	 */
	@OneToOne(cascade = CascadeType.ALL, fetch = FetchType.LAZY, mappedBy = "user")
	private Credential credential;
	
}










