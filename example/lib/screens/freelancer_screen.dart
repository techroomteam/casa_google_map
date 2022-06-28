import 'dart:async';
import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/services/background_service.dart';
import 'package:example/services/firestore_service.dart';
import 'package:example/util/util.dart';
import 'package:flutter/material.dart';

LatLng destinationLatLng = const LatLng(33.645062, 73.044726);

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

  // casamapservice
  CasaMapService casaMapService = CasaMapService();
  BackgroundService backgroundService = BackgroundService();

  int currentlocationIndex = 1;
  List<LatLng> predefinePath = [
    LatLng(33.644988, 73.041464),
    LatLng(33.643864, 73.042282),
    LatLng(33.643058, 73.042910),
    LatLng(33.643585, 73.044273),
    LatLng(33.644087, 73.044030),
    LatLng(33.644543, 73.044210),
    LatLng(33.645062, 73.044726),
  ];

  bool driverTrackingStarted = false;

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
      if (!driverTrackingStarted) {
        backgroundService.startBackgroundTracking();
      }
    }
    if (state == AppLifecycleState.resumed) {
      debugPrint("AppLifecycleState: $state");
      backgroundService.stopBackgroundTracking();

      driverTrackingStarted = false;
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
          CasaGoogleMap(
            apiKey: mapAPIKey,
            driverLatLng: myPosition != null
                ? LatLng(myPosition!.latitude, myPosition!.longitude)
                : null,
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
          ),
          Positioned(
            bottom: 20.0,
            left: 24.0,
            right: 24.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text(
                    "Start your journey",
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: () {
                    driverTrackingStarted = true;
                    startListeningForDriverLocation();
                  },
                ),
                ElevatedButton(
                  child: const Text(
                    "Open GoogleMap App",
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: () {
                    casaMapService.openMapExternalApp(
                        destinationLatLng: destinationLatLng);
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
    final casaPos = CasaPosition(
      driverLatLng: predefinePath[currentlocationIndex],
      destinationLatLng: destinationLatLng,
    );
    latlngStreamController.add(casaPos);
    currentlocationIndex += 1;
    setState(() {});

    // casaMapService
    //     .startListeningToDriverLocation(
    //         locationSettings: const LocationSettings(
    //             distanceFilter: 20, accuracy: LocationAccuracy.high))
    //     .listen((Position p) async {
    //   final casaPos = CasaPosition(
    //     driverLatLng: LatLng(p.latitude, p.longitude),
    //     destinationLatLng: destinationLatLng,
    //   );
    //   latlngStreamController.add(casaPos);
    //   myPosition = p;
    //   setState(() {});
    // });
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
