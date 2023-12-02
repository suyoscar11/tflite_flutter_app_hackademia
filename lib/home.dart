import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';

  loadCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      List<CameraDescription> cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      cameraController!.initialize().then((value) {
        if (!mounted) {
          return;
        } else {
          setState(() {
            cameraController!.startImageStream((imageStream) {
              cameraImage = imageStream;
              runModel();
            });
          });
        }
      });
    } else {
      // Handle camera permission denial
      print('Camera permission denied');
    }
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      predictions!.forEach((element) {
        setState(() {
          output = element['label'];
        });
      });
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/label.txt',
    );
  }

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Camera and TFLite'),
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(20)),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width,
            child: !cameraController!.value.isInitialized
                ? Container()
                : AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
          ),
          Text(
            output,
            style: const TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
