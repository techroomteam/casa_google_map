<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

A flutter package to make smooth animation between between two latlng in realtime. 

*A widget for flutter developers to easily integrate google map in their apps. It can be used to draw polyline between source/driver to destination. This plugin handle smooth animation between old latlng and new latlng value in realtime. It helps track driver and help getting device location permission. It also help you open GoogleMap or AppleMap apps.*

## Features
  * Make polylines (route) between two locations by providing the latitude and longitude for both the locations.
  * Smooth animation between two locations.
  * The route is customizable in terms of color and width.
  * Ask for location permission
  * The plugin also offers realtime location tracking for a driver(if any) and shows a marker on the map which updates everytimes the driver's location changes.
  * All the markers are customizable.
  * Almost all the parameters defined in [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) for the [`GoogleMap`](https://github.com/flutter/plugins/blob/master/packages/google_maps_flutter/google_maps_flutter/lib/src/google_map.dart) widget can be passed as arguments to the widget.

## Getting Started

* Get an API key at <https://cloud.google.com/maps-platform/>.

* Enable Google Map SDK for each platform.
  * Go to [Google Developers Console](https://console.cloud.google.com/).
  * Choose the project that you want to enable Google Maps on.
  * Select the navigation menu and then select "Google Maps".
  * Select "APIs" under the Google Maps menu.
  * To enable Google Maps for Android, select "Maps SDK for Android" in the "Additional APIs" section, then select "ENABLE".
  * To enable Google Maps for iOS, select "Maps SDK for iOS" in the "Additional APIs" section, then select "ENABLE".
  * To enable Directions API, select "Directions API" in the "Additional APIs" section, then select "ENABLE".
  * Make sure the APIs you enabled are under the "Enabled APIs" section.

For more details, see [Getting started with Google Maps Platform](https://developers.google.com/maps/gmp-get-started).

### Android

Specify your API key in the application manifest `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...
  <application ...
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR KEY HERE"/>
```

### iOS

Specify your API key in the application delegate `ios/Runner/AppDelegate.m`:

```objectivec
#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "GoogleMaps/GoogleMaps.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GMSServices provideAPIKey:@"YOUR KEY HERE"];
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
@end
```

Or in your swift code, specify your API key in the application delegate `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR KEY HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```
### Web

Modify web/index.html

Get an API Key for Google Maps JavaScript API. Get started [here](https://developers.google.com/maps/documentation/javascript/get-api-key).
Modify the `<head>` tag of your `web/index.html` to load the Google Maps JavaScript API, like so:
```html
<head>

  <!-- // Other stuff -->

  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY_HERE"></script>
</head>
```

## Usage

To use this plugin, add [`casa_google_map`](https://pub.dev/packages/casa_google_map) as a dependency in your pubspec.yaml file.

```yaml
  dependencies:
    flutter:
      sdk: flutter
    casa_google_map:
```

First and foremost, import the widget.
```dart
import 'package:casa_google_map/casa_google_map.dart';
```

You can now add a [`CasaGoogleMap`](https://github.com/techroomteam/casa_google_map/blob/master/lib/src/ui/casa_map.dart) widget to your widget tree and pass all the required parameters to get started.
This widget will create a route between the source and the destination LatLng's provided.
```dart
CasaGoogleMap(
    apiKey: "YOUR KEY HERE",
    sourceLatLng: LatLng(40.484000837597925, -3.369978368282318),
    destinationLatLng: LatLng(40.48017307700204, -3.3618026599287987),
),
```

Sample Usage
```dart
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
      title: 'Casa Google Map',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: return Scaffold(
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
                    startListeningForDriverLocation();
                  },
                ),
                ElevatedButton(
                  child: const Text(
                    "Open GoogleMap/AppleMap",
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
    );
  }
}



```

See the [`example`](https://github.com/techroomteam/casa_google_map/tree/master/example) directory for a complete sample app.

### Created & Maintained By `Techroom Team`

* GitHub: [@techroomteam](https://github.com/techroomteam)
* LinkedIn: [Techroom Team International](https://www.linkedin.com/company/77671370)