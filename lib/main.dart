import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart ' as pw;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share JPG, PDF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Share JPG, PDF'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              imageContainer(context),
              ElevatedButton(
                  onPressed: () async {
                    final image = await screenshotController
                        .captureFromWidget(imageContainer(context));
                    saveAndShareFile(image);
                  },
                  child: const Text("Share JPG")),
              ElevatedButton(
                  onPressed: () async {
                    final image = await screenshotController
                        .captureFromWidget(imageContainer(context));
                    await screenToPdf(image);
                  },
                  child: const Text("Share PDF")),
              ElevatedButton(
                  onPressed: () async {
                    final image = await screenshotController.capture();
                    if (image == null) return;

                    await saveImage(image);
                  },
                  child: const Text("Save to Gallery")),
            ],
          ),
        ),
      ),
    );
  }

  Future saveAndShareFile(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final image = File('${directory.path}/flutter.jpg');
    image.writeAsBytesSync(bytes);

    await Share.shareFiles([image.path]);
  }

  Future screenToPdf(Uint8List screenShot) async {
    final time = DateTime.now()
        .toIso8601String()
        .replaceAll('.', '_')
        .replaceAll(':', '_');
    final fileName = 'pdf_$time';
    pw.Document pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Expanded(
            child: pw.Image(pw.MemoryImage(screenShot), fit: pw.BoxFit.contain),
          );
        },
      ),
    );
    String path = (await getTemporaryDirectory()).path;
    File pdfFile = await File('$path/$fileName.pdf').create();

    pdfFile.writeAsBytesSync(await pdf.save());
    await Share.shareFiles([pdfFile.path]);
  }

  Future<String> saveImage(Uint8List bytes) async {
    await [Permission.storage].request();
    final time = DateTime.now()
        .toIso8601String()
        .replaceAll('.', '_')
        .replaceAll(':', '_');
    final name = 'screenshot_$time';
    final result = await ImageGallerySaver.saveImage(bytes, name: name);
    return result['filePath'];
  }

  Container imageContainer(BuildContext context) {
    return Container(
      color: Colors.yellow,
      height: 70,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: const Text(
          'This is a widget',
        ),
      ),
    );
  }
}
