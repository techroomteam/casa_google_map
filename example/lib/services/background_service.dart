import 'dart:async';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundService {
  final _fBservice = FlutterBackgroundService();

  Future<void> stopBackgroundTracking() async {
    var isRunning = await _fBservice.isRunning();
    if (isRunning) {
      _fBservice.invoke('stopService');
    }
  }

  Future<void> startBackgroundTracking() async {
    debugPrint("startBackgroundTracking1");
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("startBackgroundTracking2");
    await _fBservice.configure(
      androidConfiguration: AndroidConfiguration(
        // this will executed when app is in foreground or background in separated isolate
        onStart: startBackgroundService,
        // auto start service
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,
        // this will executed when app is in foreground in separated isolate
        onForeground: startBackgroundService,
        // you have to enable background fetch capability on xcode project
        onBackground: onIosBackground,
      ),
    );
    await _fBservice.startService();
  }

  bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    // debugPrint('FLUTTER BACKGROUND FETCH');
    return true;
  }

  // void startBackgroundService(ServiceInstance service) {
  //   debugPrint("_startBackgroundService");
  //   if (service is AndroidServiceInstance) {
  //     service.on('setAsForeground').listen((event) {
  //       service.setAsForegroundService();
  //     });
  //     service.on('setAsBackground').listen((event) {
  //       service.setAsBackgroundService();
  //     });
  //   }
  //   service.on('stopService').listen((event) {
  //     service.stopSelf();
  //   });
  //   // bring to foreground
  //   Timer.periodic(
  //     const Duration(seconds: 5),
  //     (timer) async {
  //       if (service is AndroidServiceInstance) {
  //         await service.setForegroundNotificationInfo(
  //             title: 'CASA', content: 'Running Background Service.');
  //       }
  //       debugPrint("Timer Periodic");
  //       listenDeviceLocation();
  //     },
  //   );
  // }
}
