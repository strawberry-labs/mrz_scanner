import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_scanner/src/models/process_text_image.model.dart';
import 'package:mrz_scanner/src/mrz_navigator.dart';
import 'package:vibration/vibration.dart';

final ProcessTextImage _processTextImage = ProcessTextImage();

class ImageWithScanMode {
  final InputImage image;
  final ScanMode scanMode;
  final bool enableVibration;
  
  ImageWithScanMode({
    required this.image, 
    required this.scanMode,
    this.enableVibration = true,
  });
}

class ProcessIsolate {
  bool isProcessing = false;
  bool enableVibration = true;
  final ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;
  Isolate? _isolate;
  final resultController = StreamController<String>();
  StreamSubscription<dynamic>? isolateSubscription;
  static StreamSubscription<dynamic>? isolateBSubscription;
  static final textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Stream<String> resultListener() => resultController.stream;

  Future<void> createIsolate() async {
    RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      debugPrint("Cannot get the RootIsolateToken");
      return;
    }

    _isolate = await Isolate.spawn(
      _imageProcessingIsolate,
      [rootIsolateToken, _receivePort.sendPort],
    );

    isolateSubscription = _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is String) {
        debugPrint("Received MRZ result: $message");
        if (enableVibration) {
          Vibration.vibrate(duration: 200);
          debugPrint("Vibration triggered on scan completion");
        } else {
          debugPrint("Vibration disabled - skipping vibration");
        }
        resultController.add(message);
      }
      isProcessing = false;
    });
  }

  void sendImage(InputImage image, ScanMode scanMode) {
    if (!isProcessing && _sendPort != null) {
      isProcessing = true;
      _sendPort?.send(ImageWithScanMode(
        image: image, 
        scanMode: scanMode,
        enableVibration: enableVibration,
      ));
    }
  }

  void closeIsolate() {
    _sendPort = null;
    textRecognizer.close();
    isolateSubscription?.cancel();
    isolateBSubscription?.cancel();
    _receivePort.close();
    _isolate?.kill();
    resultController.close();
    debugPrint("Isolate closed");
  }

  static void _imageProcessingIsolate(List<Object> args) {
    RootIsolateToken rootIsolateToken = args[0] as RootIsolateToken;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    SendPort sendPort = args[1] as SendPort;
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    isolateBSubscription = receivePort.listen((dynamic message) {
      if (message is ImageWithScanMode) {
        _processImage(sendPort, message);
      }
    });
  }

  static void _processImage(SendPort sendPort, ImageWithScanMode message) {
    try {
      debugPrint("Isolate process: START SCANNING - Mode: ${message.scanMode.name}");
      textRecognizer.processImage(message.image).then((recognizedText) {
        debugPrint("\n\n---------------------${recognizedText.text}");
        _processTextImage
            .firstDetectingProcess(
                recognizedText: recognizedText, 
                originalImage: message.image,
                scanMode: message.scanMode)
            .then((result) {
          debugPrint("Isolate process: result $result");
          sendPort.send(result);
        }).catchError((onError) {
          debugPrint("Isolate process: has error $onError");
        });
      });
    } catch (error) {
      debugPrint("Isolate process: has error $error");
    }
  }
}
