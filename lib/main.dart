import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:screen_loader/screen_loader.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Future<firebase_core.FirebaseApp> _initialization =
        firebase_core.Firebase.initializeApp();
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print("Something Wen Wrong");
          return Text("Something Went Wrong");
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }

        // Otherwise, show something whilst waiting for initialization to complete
        print("Loading");
        return ScreenLoaderApp(
          app: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Screen Loader',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: Container(
              child: Text("Loading"),
            ),
          ),
          globalLoader: AlertDialog(
            title: Text('Gobal Loader..'),
          ),
          globalLoadingBgBlur: 20.0,
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Firebase
  cloud_firestore.DocumentReference imagesRef =
      cloud_firestore.FirebaseFirestore.instance.collection("images").doc();

  // await saveImages(_images, sightingRef);
  Future<void> saveImages(
      File _images, cloud_firestore.DocumentReference ref) async {
    String imageURL = await uploadFile(_image);
    ref.set({
      "images": cloud_firestore.FieldValue.arrayUnion([imageURL])
    });
  }

  Future<String> uploadFile(File _image) async {
    firebase_storage.Reference storageReference = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('sightings/${_image.path}');
    firebase_storage.UploadTask uploadTask = storageReference.putFile(_image);
    await uploadTask.whenComplete(() => print("Uploading Complete"));
    print('File Uploaded');
    String returnURL;
    await storageReference.getDownloadURL().then((fileURL) {
      returnURL = fileURL;
    });
    return returnURL;
  }

  File _image; // Used only if you need a single picture

  Future getImage(bool gallery) async {
    ImagePicker picker = ImagePicker();
    PickedFile pickedFile;
    // Let user select photo from gallery
    if (gallery) {
      pickedFile = await picker.getImage(
        source: ImageSource.gallery,
      );
    }
    // Otherwise open camera to get new photo
    else {
      pickedFile = await picker.getImage(
        source: ImageSource.camera,
      );
    }

    setState(() {
      if (pickedFile != null) {
        // _images.add(File(pickedFile.path));
        _image = File(pickedFile.path); // Use if you only need a single picture
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey[300],
          appBar: AppBar(
            backgroundColor: Colors.amber[700],
            title: Text("Storage"),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image == null
                    ? Text("No Image Selected")
                    : Image.file(
                        _image,
                        height: 300,
                      ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  _image.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                  ),
                  onPressed: () => getImage(true),
                  child: Icon(
                    Icons.add_a_photo,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                    onPressed: () async =>
                        {await saveImages(_image, imagesRef)},
                    child: Text(
                      "Upload File",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
