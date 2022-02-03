import 'package:background_locator/location_dto.dart';

class LocationModel {
  final LocationDto locationDto;
  final String date;

  LocationModel(this.locationDto, this.date);

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      LocationDto.fromJson(json['location']),
      json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': locationDto.toJson(),
      'date': date,
    };
  }
}
