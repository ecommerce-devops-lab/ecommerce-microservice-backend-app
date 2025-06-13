package com.selimhorri.app.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.selimhorri.app.domain.Credential;

public interface CredentialRepository extends JpaRepository<Credential, Integer> {

	Optional<Credential> findByUsername(final String username);

	@Query("SELECT c FROM Credential c LEFT JOIN FETCH c.user")
	List<Credential> findAllWithUser();

	@Query("SELECT c FROM Credential c LEFT JOIN FETCH c.user WHERE c.credentialId = :credentialId")
	Optional<Credential> findByIdWithUser(@Param("credentialId") Integer credentialId);

	@Query("SELECT c FROM Credential c LEFT JOIN FETCH c.user WHERE c.username = :username")
	Optional<Credential> findByUsernameWithUser(@Param("username") String username);

}