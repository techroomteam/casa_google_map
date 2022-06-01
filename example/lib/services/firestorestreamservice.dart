import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/util/firebase_paths.dart';
import 'package:flutter/material.dart';

abstract class FireStreamService {
  Stream<CasaPosition> freelancerOnRouteStream();
}

class FireStoreStreamService extends FireStreamService {
  @override
  Stream<CasaPosition> freelancerOnRouteStream() {
    debugPrint("freelancerOnRouteStream Called");
    return FirebasePaths.freelancerOnRouteD
        .snapshots()
        .map((snapshot) => CasaPosition.fromMap(snapshot.data()));
  }
}
