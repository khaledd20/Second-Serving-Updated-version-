import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:secondserving/services/firebase_auth_service.dart';

import '/widgets/image_picker_button.dart';
import '../widgets/coordinate_button.dart';

class DishForm extends StatefulWidget {
  @override
  _DishFormState createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  TextEditingController _dishNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  GeoPoint? _currentCoordinates;
  File? _pickedImage;
  UploadTask? uploadTask;
  Reference? storageRef;

  @override
  void initState() {
    super.initState();
  }

  void _updateCoordinates(Future<GeoPoint> data) {
    setState(() {
      data.then((value) {
        _currentCoordinates = value;
      });
    });
  }

  void _updateImage(File image) {
    setState(() {
      _pickedImage = image;
    });
  }

  Future<void> _openAddressAutocomplete() async {
    final apiKey =
        'AIzaSyBSE-UAl4xNmb6Fk7y4ey2h6ayyeHQu2kw'; // Replace with your own API key

    Prediction? prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      mode: Mode.overlay,
      language: 'en',
      components: [Component(Component.country, 'my')],
    );

    if (prediction != null && prediction.description != null) {
      setState(() {
        _addressController.text = prediction.description!;
      });
    }
  }

  Future<void> _uploadData() async {
    EasyLoading.show(status: 'Uploading...');
    final FirebaseStorage storage =
        FirebaseStorage.instanceFor(bucket: 'secondserving-ef1f1.appspot.com');

    // Generate a unique filename for the uploaded image
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    storageRef = storage.ref().child(fileName);
    if (_pickedImage != null && storageRef != null) {
      uploadTask = storageRef!.putFile(_pickedImage!);
    }

    // Get the download URL of the uploaded image
    String? photoUrl;
    if (uploadTask != null) {
      TaskSnapshot taskSnapshot = await uploadTask!.whenComplete(() {});
      photoUrl = await taskSnapshot.ref.getDownloadURL();
    }

    final User? user = FirebaseAuth.instance.currentUser;
    final String? donorId =
        user?.uid; // Add donorID field with the current user's ID
    final String? receiverId = ''; // Initialize receiverID as blank

    final data = {
      'description': _descriptionController.text,
      'location': _addressController.text,
      'coordinates': _currentCoordinates,
      'name': _dishNameController.text,
      'photo': photoUrl,
      'status': 'not booked',
      'donorID': donorId, // Assign the donorID field
      'receiverID': receiverId, // Assign the receiverID field
      'date': DateTime.now(),
    };
    await FirebaseFirestore.instance.collection('meals').add(data);

    _dishNameController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _currentCoordinates = GeoPoint(0, 0);
    EasyLoading.dismiss();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _addressController.dispose();
    _descriptionController.dispose();
    _dishNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share your meal'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ImagePickerButton(onImageChanged: _updateImage),
              const SizedBox(height: 16.0),
              TextField(
                controller: _dishNameController,
                decoration: const InputDecoration(
                  labelText: 'Dish Name',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Your current coordinates: ${_currentCoordinates?.latitude ?? 0}, ${_currentCoordinates?.longitude ?? 0}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16.0),
              CoordinateButton(onCoordinatesChanged: _updateCoordinates),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Perform form submission actions here
                  _uploadData();
                  // Clear the form fields

                  // Show a snackbar or navigate to a new screen to indicate successful submission
                  SnackBar snackBar = SnackBar(
                    content: Text('Your meal has been shared!'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
