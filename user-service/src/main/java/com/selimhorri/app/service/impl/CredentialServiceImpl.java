package com.selimhorri.app.service.impl;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.transaction.annotation.Transactional;

import org.springframework.stereotype.Service;

import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.exception.wrapper.CredentialNotFoundException;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.helper.CredentialMappingHelper;
import com.selimhorri.app.repository.CredentialRepository;
import com.selimhorri.app.service.CredentialService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class CredentialServiceImpl implements CredentialService {

	private final CredentialRepository credentialRepository;

	@Override
	@Transactional(readOnly = true)
	public List<CredentialDto> findAll() {
		log.info("*** CredentialDto List, service; fetch all credentials *");
		return this.credentialRepository.findAllWithUser()
				.stream()
				.map(CredentialMappingHelper::map)
				.distinct()
				.collect(Collectors.toUnmodifiableList());
	}

	@Override
	@Transactional(readOnly = true)
	public CredentialDto findById(final Integer credentialId) {
		log.info("*** CredentialDto, service; fetch credential by ids *");
		return this.credentialRepository.findByIdWithUser(credentialId)
				.map(CredentialMappingHelper::map)
				.orElseThrow(() -> new CredentialNotFoundException(
						String.format("#### Credential with id: %d not found! ####", credentialId)));
	}

	@Override
	@Transactional
	public CredentialDto save(final CredentialDto credentialDto) {
		log.info("*** CredentialDto, service; save credential *");
		return CredentialMappingHelper.map(this.credentialRepository.save(CredentialMappingHelper.map(credentialDto)));
	}

	@Override
	@Transactional
	public CredentialDto update(final CredentialDto credentialDto) {
		log.info("*** CredentialDto, service; update credential *");
		return CredentialMappingHelper.map(this.credentialRepository.save(CredentialMappingHelper.map(credentialDto)));
	}

	@Override
	@Transactional
	public CredentialDto update(final Integer credentialId, final CredentialDto credentialDto) {
		log.info("*** CredentialDto, service; update credential with credentialId *");
		return CredentialMappingHelper.map(this.credentialRepository.save(
				CredentialMappingHelper.map(this.findById(credentialId))));
	}

	@Override
	@Transactional
	public void deleteById(final Integer credentialId) {
		log.info("*** Void, service; delete credential by id *");
		this.credentialRepository.deleteById(credentialId);
	}

	@Override
	@Transactional(readOnly = true)
	public CredentialDto findByUsername(final String username) {
		return CredentialMappingHelper.map(this.credentialRepository.findByUsernameWithUser(username)
				.orElseThrow(() -> new UserObjectNotFoundException(
						String.format("#### Credential with username: %s not found! ####", username))));
	}

}