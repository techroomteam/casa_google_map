import 'dart:async';
import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/main.dart';
import 'package:example/services/background_service.dart';
import 'package:example/services/firestore_service.dart';
import 'package:example/util/firebase_paths.dart';
import 'package:example/util/util.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

LatLng destinationLatLng = const LatLng(33.659996, 73.062831);

class CasaMapFreelancerExample extends StatefulWidget {
  const CasaMapFreelancerExample({Key? key}) : super(key: key);

  @override
  State<CasaMapFreelancerExample> createState() =>
      _CasaMapFreelancerExampleState();
}

class _CasaMapFreelancerExampleState extends State<CasaMapFreelancerExample>
    with WidgetsBindingObserver {
  double zoom = 15;
  late LocationPermission locationPermission;

  StreamController<CasaPosition> latlngStreamController =
      StreamController<CasaPosition>();
  StreamSubscription<CasaPosition>? streamSubscription;

  // current user location
  Position? myPosition;

  CasaPosition? casaPosition;

  bool startDiriving = false;

  // casamapservice
  CasaMapService casaMapService = CasaMapService();
  BackgroundService backgroundService = BackgroundService();

  int currentlocationIndex = 1;
  List<LatLng> predefinePath = [
    LatLng(33.652915, 73.049155),
    LatLng(33.652759, 73.049278),
    LatLng(33.652856, 73.049466),
    LatLng(33.653125, 73.049977),
    LatLng(33.653344, 73.050405),
    LatLng(33.653524, 73.050381),
  ];

  @override
  void initState() {
    checkForPermission();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    latlngStreamController.close();
    streamSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      debugPrint("AppLifecycleState: $state");
      // casaMapService.startBackgroundTracking();
      backgroundService.startBackgroundTracking();
      // startBackgroundTracking();
    }
    if (state == AppLifecycleState.resumed) {
      debugPrint("AppLifecycleState: $state");
      // casaMapService.stopBackgroundTracking();
      backgroundService.stopBackgroundTracking();
    }
  }

  checkForPermission() async {
    debugPrint("checkForPermission");
    myPosition = await casaMapService.getCurrentPosition();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("myPosition: ${myPosition == null}");
    return Scaffold(
      body: Stack(
        children: [
          myPosition != null
              ? CasaGoogleMap(
                  apiKey: mapAPIKey,
                  driverLatLng:
                      LatLng(myPosition!.latitude, myPosition!.longitude),
                  destinationLatLng: destinationLatLng,
                  driverMarkerIcon: const CasaMarkerIcon(
                      assetPath: kDefaultDriverMarkerAssetPath,
                      assetMarkerSize: Size.square(80.0)),
                  ///////////////////////////////////////////////////////
                  //////////////    OPTIONAL PARAMETERS    //////////////
                  ///////////////////////////////////////////////////////
                  routeWidth: 2,
                  driverCoordinatesStream: latlngStreamController.stream,
                  onNewCasaPositionListner: (casaPosition) {
                    this.casaPosition = casaPosition;
                    debugPrint("onNewCasaPositionListner");
                    FirestoreService.updateLocationInFirebase(casaPosition);
                  },
                )
              : const PermissionDeniedView(),
          Positioned(
            bottom: 20.0,
            left: 24.0,
            right: 24.0,
            child: Column(
              children: [
                casaPosition != null
                    ? Text(
                        'Latitude: ${casaPosition!.driverLatLng.latitude}, Longitude: ${casaPosition!.driverLatLng.longitude}')
                    : const SizedBox(width: 0.0, height: 0.0),
                myPosition != null
                    ? Text(
                        'Latitude: ${myPosition!.latitude}, Longitude: ${myPosition!.longitude}')
                    : const SizedBox(width: 0.0, height: 0.0),
                ElevatedButton(
                  child: Text(
                    !startDiriving
                        ? "Start your journey"
                        : "Reached to distination",
                  ),
                  onPressed: () {
                    startListeningForDriverLocation();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  startListeningForDriverLocation() {
    // final casaPos = CasaPosition(
    //   driverLatLng: predefinePath[currentlocationIndex],
    //   destinationLatLng: destinationLatLng,
    // );
    // latlngStreamController.add(casaPos);
    // currentlocationIndex += 1;
    // setState(() {});

    // updateLocationInFirebase(casaPos);

    casaMapService
        .startListeningToDriverLocation(
            locationSettings: const LocationSettings(
                distanceFilter: 20, accuracy: LocationAccuracy.high))
        .listen((Position p) async {
      final casaPos = CasaPosition(
        driverLatLng: LatLng(p.latitude, p.longitude),
        destinationLatLng: destinationLatLng,
      );
      latlngStreamController.add(casaPos);
      myPosition = p;
      setState(() {});
    });
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
