import 'package:casa_google_map/casa_google_map.dart';

class CasaPosition {
  final LatLng driverLatLng;
  final LatLng destinationLatLng;
  final bool? isOnRoute;
  final List<LatLng>? route;

  CasaPosition({
    required this.driverLatLng,
    required this.destinationLatLng,
    this.isOnRoute,
    this.route,
  });

  // Map<String, dynamic> toMap() {
  //   return {
  //     'currentlocation': location.toJson(),
  //     'is_on_route': isOnRoute,
  //     // 'route': route.map((org) => org.toJson()).toList(),
  //   };
  // }

  Map<String, dynamic> toMap() {
    return {
      'driverlatlng': latlngToMap(driverLatLng),
      'destinationlatlng': latlngToMap(destinationLatLng),
      'is_on_route': isOnRoute,
      'route': route != null
          ? route!.map((latlng) => latlngToMap(latlng)).toList()
          : [],
    };
  }

  CasaPosition.fromMap(map)
      : driverLatLng = LatLng(
            map['driverlatlng']['latitude'], map['driverlatlng']['longitude']),
        destinationLatLng = LatLng(map['destinationlatlng']['latitude'],
            map['destinationlatlng']['longitude']),
        isOnRoute = map['is_on_route'],
        route = List<LatLng>.from(
          map['route']?.map(
                  (item) => LatLng(item['latitude'], item['longitude'])) ??
              [],
        );

  latlngToMap(LatLng latLng) {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }

  // LatLng latlngFromMap(map) {
  //   return LatLng(map['latitude'], map['longitude']);
  // }
}
