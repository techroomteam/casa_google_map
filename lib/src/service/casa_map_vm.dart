import 'dart:async';
import 'dart:io';
import 'package:casa_google_map/casa_google_map.dart';
import 'package:casa_google_map/src/service/permission_service.dart';
import 'package:casa_google_map/src/util/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_marker_animation/core/ripple_marker.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapTolkit;
import 'package:url_launcher/url_launcher.dart';

class CasaMapService {
  /// setState function
  late void Function(Function() fn) _setState;

  /// source  [LatLng]
  LatLng? _sourceLatLng;

  /// destination [LatLng]
  late LatLng? _destinationLatLng;

  /// driver  [LatLng]
  late LatLng? _driverLatLng;

  // /// Google maps controller
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  /// source marker info
  CasaMarkerIcon? _sourceMarkerIcon;

  /// destination marker info
  CasaMarkerIcon? _destinationMarkerIcon;

  /// driver marker info
  CasaMarkerIcon? _driverMarkerIcon;

  /// A [Stream] of [LatLng] objects for the driver
  /// used to render [_driverMarkerIcon] on the map
  /// with the provided [LatLng] objects.
  ///
  /// See also:
  ///   * [_onTapDriverInfoWindow] parameter.
  ///   * [_onTapDriverMarker] parameter.
  ///   * [_driverName] parameter.
  ///
  /// If null, the [_driverMarkerIcon] is not rendered.
  StreamSubscription<CasaPosition>? _driverCoordinates;

  /// The initial location of the map's camera.
  LatLng? _defaultCameraLocation;

  /// The initial zoom of the map's camera.
  double? _defaultCameraZoom;

  /// Markers to be placed on the map.
  // final _markers = <Marker>{};
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};

  /// Polylines to be placed on the map.
  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  /// Color of the route made between [_sourceLatLng] and [_destinationLatLng].
  Color? _routeColor;

  /// Width of the route made between [_sourceLatLng] and [_destinationLatLng].
  int? _routeWidth;

  /// The total distance between the source and the destination.
  String? totalDistance;

  /// The total time between the source and the destination.
  String? totalTime;

  /// Google maps API Key
  static late String _apiKey;

  /// Returns the Google Maps API Key passed to the [GoogleMapsWidget].
  static String get apiKey => _apiKey;

  /// Returns the [_defaultCameraLocation].
  /// If [_defaultCameraLocation] is null, returns [_sourceLatLng].
  LatLng get defaultCameraLocation =>
      _defaultCameraLocation ??
      _sourceLatLng ??
      _destinationLatLng ??
      const LatLng(33.653761, 73.049710);

  /// Returns the [_defaultCameraZoom].
  /// If [_defaultCameraZoom] is null, returns [Constants.kDefaultCameraZoom].
  double get defaultCameraZoom =>
      _defaultCameraZoom ?? Constants.kDefaultCameraZoom;

  /// Returns markers to be placed on the map.
  Map<MarkerId, Marker> get markers => _markers;

  /// Returns polylines to be placed on the map.
  Map<PolylineId, Polyline> get polylines => _polylines;

  /// Return [GoogleMapController] object
  Completer<GoogleMapController> get mapControllerCompleter =>
      _mapControllerCompleter;

  /// Sets [GoogleMapController] from [GoogleMap] callback to [_mapController].
  void setController(GoogleMapController controller) {
    mapControllerCompleter.complete(controller);
    _mapController = controller;

    if (_driverLatLng != null) _centerPolyline();
  }

  /// Whether to show the driver marker at [_driverLatLng].
  ///
  /// Defaults to true.
  late bool _showSourceMarker;

  /// Whether to show the destination marker at [_destinationLatLng].
  ///
  /// Defaults to true.
  late bool _showDestinationMarker;

  /// Whether to show the driver marker.
  ///
  /// Defaults to true.
  late bool _showDriverMarker;

  /// Whether to show the generated polyline from [_sourceLatLng]
  /// to [_destinationLatLng].
  ///
  /// Defaults to true.
  late bool _showPolyline;

  ///
  Function(CasaPosition)? _onNewCasaPositionListner;

  ///
  late CasaMapViewType _casaMapViewType;

  final polylineCoordinates = <LatLng>[];
  final mapTolkitPolylineCoordinates = <mapTolkit.LatLng>[];

  bool isLocationOnPath = false;
  int currentSegmentIndex = 0;

  ///
  bool shouldCenterPolyline = true;

  // services
  final PermissionService _permissionService = PermissionService();

  int stopCounter = 0;
  bool animationStopped = true;

  /// setting source and destination markers
  void _setSourceDestinationMarkers() async {
    if (_showSourceMarker && _sourceLatLng != null) {
      var markerId = const MarkerId('source');
      _markers[markerId] = RippleMarker(
        markerId: markerId,
        icon: (await _sourceMarkerIcon?.bitmapDescriptor)!,
        position: _sourceLatLng!,
        anchor: const Offset(0.5, 0.5), // Extra....
        ripple: false,
      );
    }

    if (_showDriverMarker && _driverLatLng != null) {
      var markerId = const MarkerId('driver');
      _markers[markerId] = RippleMarker(
        markerId: markerId,
        icon: (await _driverMarkerIcon?.bitmapDescriptor)!,
        position: _driverLatLng!,
        anchor: const Offset(0.5, 0.5), // Extra....
        ripple: false,
      );
    }

    if (_showDestinationMarker && _destinationLatLng != null) {
      var markerId = const MarkerId('destination');
      _markers[markerId] = RippleMarker(
        markerId: markerId,
        icon: (await _destinationMarkerIcon?.bitmapDescriptor)!,
        position: _destinationLatLng!,
        anchor: const Offset(0.5, 0.5), // Extra....
        ripple: false,
      );
    }

    _setState(() {});
    // notifyListeners();
  }

  /// Build polylines from [_sourceLatLng] to [_destinationLatLng].
  ///
  /// If already have a polyline then first clear it
  ///
  /// If [CasaMapViewType.driver] then this method will draw polyline between [_driverLatLng] and [_destinationLatLng]
  ///
  /// If [CasaMapViewType.customer] then this method will draw polyline with help of [CasaPosition.route]
  ///
  /// In case of customer we don't need to reroute, we can store driver side data in firebase and display polyline with help of that data
  Future<void> _buildPolyLines(
      {bool ignoreMapType = false, CasaPosition? casaPosition}) async {
    // clear coordinates
    polylineCoordinates.clear();
    mapTolkitPolylineCoordinates.clear();

    debugPrint("Inside build polylines");

    if (_casaMapViewType == CasaMapViewType.driver || ignoreMapType) {
      debugPrint("Inside build polylines2");

      //
      final polylinePoint = PolylinePoints();

      // get heading value before retouring
      final compassEvent = await FlutterCompass.events!.first;

      var result = await polylinePoint.getRouteBetweenCoordinates(
        CasaMapService.apiKey,
        PointLatLng(
          _sourceLatLng != null
              ? _sourceLatLng!.latitude
              : _driverLatLng!.latitude,
          _sourceLatLng != null
              ? _sourceLatLng!.longitude
              : _driverLatLng!.longitude,
        ),
        PointLatLng(
            _destinationLatLng!.latitude, _destinationLatLng!.longitude),
        heading: compassEvent.heading!.round(),
      );

      debugPrint("Inside build polylines3");
      debugPrint("Result Points:${result.points}");

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          mapTolkitPolylineCoordinates
              .add(mapTolkit.LatLng(point.latitude, point.longitude));
        }
      }
    } else {
      // if view type is customer, we don't need to reroute
      // we should pass data from firebase and redraw polyline

      polylineCoordinates.addAll(casaPosition!.route!);
    }

    var id = const PolylineId('poly_line');

    debugPrint("buildPolylines: ${polylineCoordinates.toList()}");

    final polyline = Polyline(
      polylineId: id,
      color: _routeColor ?? Constants.kRouteColor,
      width: _routeWidth ?? Constants.kRouteWidth,
      points: polylineCoordinates,
    );

    _polylines[id] = polyline;

    _setState(() {});
  }

  /// This function takes in a [Stream] of [LatLng]-[locationStream]
  /// and check if new location is onPolylinePath, if yes then
  /// simply called [_updateDriverMarker] to animate to new location
  ///
  /// If new location is not on Path then
  /// 1. Get [getCurrentLocationSegmentIndex] from [polylineCoordinates] (polyline path)
  /// 2. Request new polyline and move to new driver location
  Future<void> _listenToDriverCoordinates(
      Stream<CasaPosition> locationStream) async {
    debugPrint("_listenToDriverCoordinates");

    _driverCoordinates = locationStream.listen((casaPos) async {
      if (!_showDriverMarker) return;

      debugPrint("_listenToDriverCoordinates: ${casaPos.toMap()}");

      late LatLng newDriverLocation;

      // update driver location when we have new updated data
      // this record is also used in [onStopMarkerAnimation] function to make sure we reach to current driver segment on polyline path
      _driverLatLng = casaPos.driverLatLng;
      // if destination location was null before
      bool destinationIconNeedToBeSet = false;
      if (_destinationLatLng == null) {
        destinationIconNeedToBeSet = true;
      }
      // on customer side we don't want to ask for location, we will just pass the data we already have
      _destinationLatLng = casaPos.destinationLatLng;

      if (destinationIconNeedToBeSet) {
        _setSourceDestinationMarkers();
      }

      isLocationOnPath = mapTolkit.PolygonUtil.isLocationOnPath(
        mapTolkit.LatLng(
            casaPos.driverLatLng.latitude, casaPos.driverLatLng.longitude),
        mapTolkitPolylineCoordinates,
        false,
        tolerance: 10,
      );

      if (isLocationOnPath && polylineCoordinates.isNotEmpty) {
        currentSegmentIndex =
            getCurrentLocationSegmentIndex(casaPos.driverLatLng);
        debugPrint("currentSegmentIndex: $currentSegmentIndex");
        if (currentSegmentIndex > 0) {
          final newLocation = LatLng(polylineCoordinates[1].latitude,
              polylineCoordinates[1].longitude);
          newDriverLocation = newLocation;
        } else {
          newDriverLocation = casaPos.driverLatLng;
        }
      } else {
        newDriverLocation = casaPos.driverLatLng;
        await _buildPolyLines(casaPosition: casaPos, ignoreMapType: true);

        if (shouldCenterPolyline) {
          shouldCenterPolyline = false;
          debugPrint('Center Polyline');
          await _centerPolyline();
        }
      }

      debugPrint("isLocationOnPath: $isLocationOnPath");

      //
      final casaPosition = CasaPosition(
        driverLatLng: newDriverLocation,
        destinationLatLng: casaPos.destinationLatLng,
        isOnRoute: isLocationOnPath,
        route: polylineCoordinates,
      );

      if (_onNewCasaPositionListner != null) {
        _onNewCasaPositionListner!(casaPosition);
      }

      debugPrint("animationStopped: $animationStopped");
      if (animationStopped) {
        _updateDriverMarker(newDriverLocation);
      }
    });
  }

  /// This method will help us to animate from current location to new location
  _updateDriverMarker(LatLng coordinate) async {
    final driverMarker = (await _driverMarkerIcon?.bitmapDescriptor)!;

    var markerId = const MarkerId('driver');
    _markers[markerId] = RippleMarker(
      markerId: markerId,
      icon: driverMarker,
      position: coordinate,
      anchor: const Offset(0.5, 0.5), // Extra....
      ripple: false,
    );

    _setState(() {});
  }

  ///
  int getCurrentLocationSegmentIndex(LatLng newLocation) {
    var markerInd = 0;
    debugPrint('polylineCoordinates.length: ${polylineCoordinates.length}');
    for (var i = 0; i < polylineCoordinates.length; i++) {
      int index;
      if (i == polylineCoordinates.length - 1) {
        index = 1;
      } else {
        index = i + 1;
      }

      var polylineCoordinateList = <mapTolkit.LatLng>[
        mapTolkit.LatLng(
            polylineCoordinates[i].latitude, polylineCoordinates[i].longitude),
        mapTolkit.LatLng(polylineCoordinates[index].latitude,
            polylineCoordinates[index].longitude)
      ];
      final pointFromSourceToolkit =
          mapTolkit.LatLng(newLocation.latitude, newLocation.longitude);
      var onPath = mapTolkit.PolygonUtil.isLocationOnPath(
          pointFromSourceToolkit, polylineCoordinateList, false,
          tolerance: 4);
      if (onPath) {
        markerInd = polylineCoordinates.indexOf(polylineCoordinates[i]);
        break;
      }
    }

    return markerInd;
  }

  ///
  Future<void> onStopMarkerAnimation(LatLng latLng) async {
    stopCounter += 1;
    debugPrint("onStopMarkerAnimation: $stopCounter");

    if (!mapControllerCompleter.isCompleted) return;

    LatLng nextLocation = _driverLatLng!;
    if (currentSegmentIndex == 1) {
      polylineCoordinates.removeAt(0);
      currentSegmentIndex -= 1;
      //

      _updateDriverMarker(nextLocation);
    } else if (currentSegmentIndex > 1) {
      polylineCoordinates.removeAt(0);
      nextLocation = LatLng(
          polylineCoordinates[1].latitude, polylineCoordinates[1].longitude);
      currentSegmentIndex -= 1;

      _updateDriverMarker(nextLocation);
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      animationStopped = true;
      // debugPrint("animationStopped: $animationStopped");
    });
  }

  /// Initialize all the parameters.
  void initialize({
    required void Function(void Function() fn) setState,
    required String apiKey,
    void Function(CasaPosition)? onNewCasaPositionListner,
    LatLng? sourceLatLng,
    required LatLng? driverLatLng,
    required LatLng? destinationLatLng,
    // void Function(LatLng)? onTapSourceInfoWindow,
    // void Function(LatLng)? onTapDestinationInfoWindow,
    // void Function(LatLng)? onTapDriverInfoWindow,
    void Function(LatLng)? onTapSourceMarker,
    void Function(LatLng)? onTapDestinationMarker,
    void Function(LatLng)? onTapDriverMarker,
    void Function(String?)? totalTimeCallback,
    void Function(String?)? totalDistanceCallback,
    Stream<CasaPosition>? driverCoordinatesStream,
    LatLng? defaultCameraLocation,
    double? defaultCameraZoom,
    Color? routeColor,
    int? routeWidth,
    required CasaMapViewType casaMapViewType,
    CasaMarkerIcon? sourceMarkerIcon,
    CasaMarkerIcon? destinationMarkerIcon,
    CasaMarkerIcon? driverMarkerIcon,
    bool showSourceMarker = true,
    bool showDestinationMarker = true,
    bool showDriverMarker = true,
    bool showPolyline = true,
  }) {
    _defaultCameraLocation = defaultCameraLocation;
    _sourceLatLng = sourceLatLng;
    _driverLatLng = driverLatLng;
    _destinationLatLng = destinationLatLng;
    _apiKey = apiKey;
    _setState = setState;
    _defaultCameraZoom = defaultCameraZoom;

    _routeColor = routeColor;
    _routeWidth = routeWidth;
    _sourceMarkerIcon = sourceMarkerIcon;
    _destinationMarkerIcon = destinationMarkerIcon;
    _driverMarkerIcon = driverMarkerIcon;
    _showSourceMarker = showSourceMarker;
    _showDestinationMarker = showDestinationMarker;
    _showDriverMarker = showDriverMarker;
    _showPolyline = showPolyline;

    _onNewCasaPositionListner = onNewCasaPositionListner;
    _casaMapViewType = casaMapViewType;

    _setState(() {
      _setSourceDestinationMarkers();

      if (_showPolyline &&
          _driverLatLng != null &&
          _destinationLatLng != null) {
        _buildPolyLines(ignoreMapType: true);
      }

      if (driverCoordinatesStream != null) {
        _listenToDriverCoordinates(driverCoordinatesStream);
      }
    });
  }

  /// Clear all the fields.
  /// Dispose off controllers.
  void clear() {
    _sourceMarkerIcon = null;
    _destinationMarkerIcon = null;
    _driverMarkerIcon = null;
    _defaultCameraLocation = null;
    _defaultCameraZoom = null;
    _routeColor = null;
    _routeWidth = null;
    totalDistance = null;
    totalTime = null;

    _driverCoordinates?.cancel();
    _markers.clear();
    _polylines.clear();
  }

  // Geolocator start
  /// This function will first if device have location permission if not then it will ask for permission
  Future<Position> getCurrentPosition() async =>
      _permissionService.determinePosition();

  ///
  Stream<Position> startListeningToDriverLocation(
          {LocationSettings? locationSettings}) =>
      _permissionService.startDriving(locationSettings: locationSettings);

  // Geolocator end

  /// this method required destination [LatLng]
  Future<void> openMapExternalApp({required LatLng destinationLatLng}) async {
    String googleMapUrl =
        'https://www.google.com/maps/search/?api=1&query=${destinationLatLng.latitude},${destinationLatLng.longitude}';
    String appleMapUrl =
        'https://maps.apple.com/?q=${destinationLatLng.latitude},${destinationLatLng.longitude}';
    if (Platform.isAndroid) {
      try {
        if (await canLaunchUrl(Uri(path: googleMapUrl))) {
          await launchUrl(Uri(path: googleMapUrl));
        }
      } catch (error) {
        throw ("Cannot launch Google map");
      }
    }
    if (Platform.isIOS) {
      try {
        if (await canLaunchUrl(Uri(path: appleMapUrl))) {
          await launchUrl(Uri(path: appleMapUrl));
        }
      } catch (error) {
        throw ("Cannot launch Apple map");
      }
    }
  }

  // cetner polyline
  Future<void> _centerPolyline() async {
    LatLngBounds bounds;
    if (_driverLatLng!.latitude > _destinationLatLng!.latitude &&
        _driverLatLng!.latitude > _destinationLatLng!.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(
              _destinationLatLng!.latitude, _destinationLatLng!.longitude),
          northeast: LatLng(_driverLatLng!.latitude, _driverLatLng!.longitude));
    } else if (_driverLatLng!.longitude > _destinationLatLng!.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(_driverLatLng!.latitude, _driverLatLng!.longitude),
          northeast:
              LatLng(_destinationLatLng!.latitude, _driverLatLng!.longitude));
    } else if (_driverLatLng!.latitude > _destinationLatLng!.latitude) {
      bounds = LatLngBounds(
          southwest:
              LatLng(_destinationLatLng!.latitude, _driverLatLng!.longitude),
          northeast: LatLng(_driverLatLng!.latitude, _driverLatLng!.longitude));
    } else {
      bounds = LatLngBounds(
          southwest: LatLng(_driverLatLng!.latitude, _driverLatLng!.longitude),
          northeast: LatLng(
              _destinationLatLng!.latitude, _destinationLatLng!.longitude));
    }
    var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 70.0);
    await _animateToCenter(cameraUpdate, _mapController);
  }

  Future<void> _animateToCenter(CameraUpdate u, GoogleMapController c) async {
    await c.animateCamera(u);
    var l1 = await c.getVisibleRegion();
    var l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      _animateToCenter(u, c);
    }
  }
}
