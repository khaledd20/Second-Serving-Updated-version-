import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerButton extends StatefulWidget {
  final Function(File) onImageChanged;
  ImagePickerButton({required this.onImageChanged});
  @override
  _ImagePickerButtonState createState() => _ImagePickerButtonState();
}

class _ImagePickerButtonState extends State<ImagePickerButton> {
  File? _pickedImage;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // ignore: deprecated_member_use
    final _pickedImage = await picker.getImage(source: source);

    if (_pickedImage != null) {
      widget.onImageChanged(File(_pickedImage.path));
      setState(() {
        this._pickedImage = File(_pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _pickedImage != null
            ? Image.file(
                _pickedImage!,
                width: 400.0,
                height: 400.0,
              )
            : Placeholder(
                color: Color.fromARGB(58, 62, 64, 66),
              ), // Display the picked image or a placeholder if no image is picked
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.green)),
          onPressed: () => _pickImage(ImageSource.camera),
          child: Text('Take a photo'),
        ),
      ],
    );
  }
}
