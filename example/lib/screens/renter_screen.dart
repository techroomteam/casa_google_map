import 'dart:async';
import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/services/firestorestreamservice.dart';
import 'package:example/util/firebase_paths.dart';
import 'package:example/util/util.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CasaMapRenterExample extends StatefulWidget {
  const CasaMapRenterExample({Key? key}) : super(key: key);

  @override
  State<CasaMapRenterExample> createState() => _CasaMapRenterExampleState();
}

class _CasaMapRenterExampleState extends State<CasaMapRenterExample> {
  double zoom = 15;

  bool startDiriving = false;

  // casamapservice
  CasaMapService casaMapService = CasaMapService();

  FireStreamService fireStreamService = FireStoreStreamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CasaGoogleMap(
            apiKey: mapAPIKey,
            driverMarkerIcon: const CasaMarkerIcon(
              assetPath: kDefaultDriverMarkerAssetPath,
              assetMarkerSize: Size.square(80.0),
            ),
            ///////////////////////////////////////////////////////
            //////////////    OPTIONAL PARAMETERS    //////////////
            ///////////////////////////////////////////////////////
            routeWidth: 2,
            casaMapViewType: CasaMapViewType.customer,
            driverCoordinatesStream:
                fireStreamService.freelancerOnRouteStream(),
          )
        ],
      ),
    );
  }

  Future<void> updateLocationInFirebase(CasaPosition casaPosition) async {
    await FirebasePaths.freelancerOnRouteD.set(casaPosition.toMap());
  }
}

class PermissionDeniedView extends StatelessWidget {
  final VoidCallback? onRequestPermission;
  const PermissionDeniedView({this.onRequestPermission, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Permission is Denied"),
          TextButton(
            onPressed: onRequestPermission,
            child: const Text('Ask for permission'),
          ),
        ],
      ),
    );
  }
}
