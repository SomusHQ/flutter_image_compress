import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'const/resource.dart';
// import 'package:image_picker/image_picker.dart';

void main() {
  runApp(new MyApp());
  FlutterImageCompress.showNativeLog = true;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> compress() async {
    var img = AssetImage("img/img.jpg");
    print("pre compress");
    var config = new ImageConfiguration();

    AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);

    var beforeCompress = data.lengthInBytes;
    print("beforeCompress = $beforeCompress");

    var result =
        await FlutterImageCompress.compressWithList(data.buffer.asUint8List());

    print("after = ${result?.length ?? 0}");
  }

  ImageProvider provider;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: <Widget>[
            AspectRatio(
              child: Image(
                image: provider ?? AssetImage("img/img.jpg"),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              aspectRatio: 1 / 1,
            ),
            FlatButton(
              child: Text('CompressFile and rotate 180'),
              onPressed: _testCompressFile,
            ),
            FlatButton(
              child: Text('CompressAndGetFile and rotate 90'),
              onPressed: getFileImage,
            ),
            FlatButton(
              child: Text('CompressAsset and rotate 135'),
              onPressed: () => testCompressAsset("img/img.jpg"),
            ),
            FlatButton(
              child: Text('CompressList and rotate 270'),
              onPressed: compressListExample,
            ),
            FlatButton(
              child: Text('test compress auto angle'),
              onPressed: _compressAssetAndAutoRotate,
            ),
            FlatButton(
              child: Text('Test png '),
              onPressed: _compressPngImage,
            ),
            FlatButton(
              child: Text('Format transparent PNG'),
              onPressed: _compressTransPNG,
            ),
            FlatButton(
              child: Text('Restore transparent PNG'),
              onPressed: _restoreTransPNG,
            ),
            FlatButton(
              child: Text('Keep exif image'),
              onPressed: _compressImageAndKeepExif,
            ),
            FlatButton(
              child: Text("download and compress big image"),
              onPressed: _downloadAndCompressBigImage,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.computer),
          onPressed: () => setState(() => this.provider = null),
          tooltip: "show origin asset",
        ),
      ),
    );
  }

  Future<Directory> getTemporaryDirectory() async {
    return Directory.systemTemp;
  }

  void _testCompressFile() async {
    var img = AssetImage("img/img.jpg");
    print("pre compress");
    var config = new ImageConfiguration();

    AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    var dir = await path_provider.getTemporaryDirectory();
    print('dir = $dir');

    File file = File("${dir.absolute.path}/test.png");
    file.writeAsBytesSync(data.buffer.asUint8List());

    List<int> list = await testCompressFile(file);
    ImageProvider provider = MemoryImage(Uint8List.fromList(list));
    this.provider = provider;
    setState(() {});
  }

  void getFileImage() async {
    var img = AssetImage("img/img.jpg");
    print("pre compress");
    var config = new ImageConfiguration();

    AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    var dir = await path_provider.getTemporaryDirectory();

    File file = File("${dir.absolute.path}/test.png");
    file.writeAsBytesSync(data.buffer.asUint8List());

    var targetPath = dir.absolute.path + "/temp.png";
    var imgFile = await testCompressAndGetFile(file, targetPath);

    provider = FileImage(imgFile);
    setState(() {});
  }

  Future<List<int>> testCompressFile(File file) async {
    print("testCompressFile");
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 2300,
      minHeight: 1500,
      quality: 94,
      rotate: 180,
    );
    print(file.lengthSync());
    print(result.length);
    return result;
  }

  Future<File> testCompressAndGetFile(File file, String targetPath) async {
    print("testCompressAndGetFile");
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: 1024,
      minHeight: 1024,
      rotate: 90,
    );

    print(file.lengthSync());
    print(result.lengthSync());

    return result;
  }

  Future testCompressAsset(String assetName) async {
    print("testCompressAsset");
    var list = await FlutterImageCompress.compressAssetImage(
      assetName,
      minHeight: 1920,
      minWidth: 1080,
      quality: 96,
      rotate: 135,
    );

    this.provider = MemoryImage(Uint8List.fromList(list));
    setState(() {});
  }

  Future compressListExample() async {
    var img = AssetImage("img/img.jpg");
    print("pre compress");
    var config = new ImageConfiguration();

    AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    var list = List<int>.from(data.buffer.asUint8List());

    // print(list);

    list = await testComporessList(list);

    var memory = Uint8List.fromList(list);
    setState(() {
      this.provider = MemoryImage(memory);
    });
  }

  Future<List<int>> testComporessList(List<int> list) async {
    var result = await FlutterImageCompress.compressWithList(
      list,
      minHeight: 1920,
      minWidth: 1080,
      quality: 96,
      rotate: 270,
    );
    print(list.length);
    print(result.length);
    return result;
  }

  void writeToFile(List<int> list, String filePath) {
    var file = File(filePath);
    file.writeAsBytes(list, flush: true, mode: FileMode.write);
  }

  void _compressAssetAndAutoRotate() async {
    var result = await FlutterImageCompress.compressAssetImage(
      R.IMG_AUTO_ANGLE_JPG,
      minWidth: 1000,
      quality: 95,
      // autoCorrectionAngle: false,
    );
    var u8list = Uint8List.fromList(result);
    this.provider = MemoryImage(u8list);
    setState(() {});
  }

  void _compressPngImage() async {
    var result = await FlutterImageCompress.compressAssetImage(
      R.IMG_HEADER_PNG,
      minWidth: 300,
      minHeight: 500,
    );

    var u8list = Uint8List.fromList(result);
    this.provider = MemoryImage(u8list);
    setState(() {});
  }

  void _compressTransPNG() async {
    var result = await FlutterImageCompress.compressAssetImage(
      R.IMG_TRANSPARENT_BACKGROUND_PNG,
      minHeight: 100,
      minWidth: 100,
      format: CompressFormat.png,
    );

    var u8list = Uint8List.fromList(result);
    this.provider = MemoryImage(u8list);
    setState(() {});
  }

  void _restoreTransPNG() async {
    this.provider = AssetImage(R.IMG_TRANSPARENT_BACKGROUND_PNG);
    setState(() {});
  }

  void _compressImageAndKeepExif() async {
    var result = await FlutterImageCompress.compressAssetImage(
      R.IMG_AUTO_ANGLE_JPG,
      minWidth: 500,
      minHeight: 600,
      // autoCorrectionAngle: false,
      keepExif: true,
    );

    this.provider = MemoryImage(Uint8List.fromList(result));
    setState(() {});

    // var dir = (await path_provider.getTemporaryDirectory()).path;
    // var f = File("$dir/tmp.jpg");
    // f.writeAsBytesSync(result);
    // print("f.path = ${f.path}");
  }

  void _downloadAndCompressBigImage() async {
    final url = "http://172.16.100.245:5000/1.jpg";
    final tmpDir = await path_provider.getExternalStorageDirectory();
    final resultFile = File("${tmpDir.path}/tmp.jpg");
    if (resultFile.existsSync()) {
      resultFile.deleteSync();
    }
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();
    print(resultFile.path);
    resp.listen((data) {
      resultFile.writeAsBytesSync(data, mode: FileMode.append);
    }).onDone(() async {
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          resultFile.path,
          "${tmpDir.path}/result.jpg",
        );
        if (result == null) {
          return;
        }
        print(result.lengthSync());
        print(result.path);
      } on Exception catch (e) {
        print(e);
      } on Error catch (e) {
        print(e);
      } finally {
        client.close();
      }
    });
  }
}

double calcScale({
  double srcWidth,
  double srcHeight,
  double minWidth,
  double minHeight,
}) {
  var scaleW = srcWidth / minWidth;
  var scaleH = srcHeight / minHeight;

  var scale = math.max(1.0, math.min(scaleW, scaleH));

  return scale;
}
