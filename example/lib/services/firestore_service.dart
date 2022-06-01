import 'package:casa_google_map/casa_google_map.dart';
import 'package:example/util/firebase_paths.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static Future<void> updateLocationInFirebase(
      CasaPosition casaPosition) async {
    debugPrint("***updateLocationInFirebase***");
    try {
      await Firebase.initializeApp();
      await FirebasePaths.freelancerOnRouteD.set(casaPosition.toMap());
    } catch (e) {
      debugPrint("updateLocationInFirebase Exception: $e");
    }
  }
}
