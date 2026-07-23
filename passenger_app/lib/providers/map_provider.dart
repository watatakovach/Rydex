import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  LatLng? _destination;

  LatLng? get currentLocation => _currentLocation;
  LatLng? get destination => _destination;

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }

  void setDestination(LatLng location) {
    _destination = location;
    notifyListeners();
  }
}