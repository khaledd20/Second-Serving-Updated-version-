import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CoordinateButton extends StatelessWidget {
  final Function(Future<GeoPoint>) onCoordinatesChanged;
  CoordinateButton({required this.onCoordinatesChanged});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.green)),
      onPressed: () {
        onCoordinatesChanged(_getCurrentLocation());
      },
      child: Text('Get Current Location'),
    );
  }

  Future<GeoPoint> _getCurrentLocation() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      print('Error: $e');
    }

    return GeoPoint(0, 0);
  }
}
