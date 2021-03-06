import 'dart:async';
import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/screens/freelancer_screen.dart';
import 'package:example/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CasaMapFreelancerExample(),
    );
  }
}

void startBackgroundService(ServiceInstance service) {
  debugPrint("_startBackgroundService");
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  // bring to foreground
  Timer.periodic(
    const Duration(seconds: 5),
    (timer) async {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
            title: 'CASA', content: 'Running Background Service.');
      }

      debugPrint("Timer Periodic");

      listenDeviceLocation();
    },
  );
}

listenDeviceLocation() {
  debugPrint("Hurra listenDeviceLocation working");
  CasaMapService casaMapService = CasaMapService();
  casaMapService
      .startListeningToDriverLocation(
          locationSettings: const LocationSettings(
              distanceFilter: 20, accuracy: LocationAccuracy.high))
      .listen((position) {
    CasaPosition casaPosition = CasaPosition(
        driverLatLng: LatLng(position.latitude, position.longitude),
        destinationLatLng: destinationLatLng);
    FirestoreService.updateLocationInFirebase(casaPosition);
  });
}
