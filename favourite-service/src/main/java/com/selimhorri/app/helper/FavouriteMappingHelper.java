package com.selimhorri.app.helper;

import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.dto.UserDto;

public interface FavouriteMappingHelper {

	public static FavouriteDto map(final Favourite favourite) {
		return FavouriteDto.builder()
				.userId(favourite.getUserId())
				.productId(favourite.getProductId())
				.likeDate(favourite.getLikeDate())
				.userDto(favourite.getUserId() != null ? UserDto.builder()
						.userId(favourite.getUserId())
						.build() : null)
				.productDto(favourite.getProductId() != null ? ProductDto.builder()
						.productId(favourite.getProductId())
						.build() : null)
				.build();
	}

	public static Favourite map(final FavouriteDto favouriteDto) {
		return Favourite.builder()
				.userId(favouriteDto.getUserId())
				.productId(favouriteDto.getProductId())
				.likeDate(favouriteDto.getLikeDate())
				.build();
	}

}