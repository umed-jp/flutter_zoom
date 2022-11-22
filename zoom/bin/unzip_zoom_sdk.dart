import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:archive/archive.dart';

void main(List args) async {
  var location = Platform.script.toString();
  var isNewFlutter = location.contains(".snapshot");
  if (isNewFlutter) {
    var sp = Platform.script.toFilePath();
    var sd = sp.split(Platform.pathSeparator);
    sd.removeLast();
    var scriptDir = sd.join(Platform.pathSeparator);
    var packageConfigPath = [scriptDir, '..', '..', '..', 'package_config.json']
        .join(Platform.pathSeparator);
    var jsonString = File(packageConfigPath).readAsStringSync();
    Map<String, dynamic> packages = jsonDecode(jsonString);
    var packageList = packages["packages"];
    String? zoomFileUri;
    for (var package in packageList) {
      if (package["name"] == "zoom") {
        zoomFileUri = package["rootUri"];
        break;
      }
    }
    if (zoomFileUri == null) {
      print("flutter_zoom_sdk package not found!");
      return;
    }
    location = zoomFileUri;
  }
  if (Platform.isWindows) {
    location = location.replaceFirst("file:///", "");
  } else {
    location = location.replaceFirst("file://", "");
  }
  if (!isNewFlutter) {
    location = location.replaceFirst("/bin/unzip_zoom_sdk.dart", "");
  }

  await checkAndDownloadSDK(location);

  print('Complete');
}

Future checkAndDownloadSDK(String location) async {
  var iosSDKFile = location +
      '/ios/MobileRTC.xcframework/ios-arm64/MobileRTC.framework/MobileRTC';
  bool exists = await File(iosSDKFile).exists();

  if (!exists) {
    await downloadFile(
        Uri.parse('https://www.dropbox.com/s/9i5v579i6926s5y/MobileRTC?dl=0'),
        iosSDKFile);
  }

  var iosSimulateSDKFile = location +
      '/ios/MobileRTC.xcframework/ios-x86_64-simulator/MobileRTC.framework/MobileRTC';
  exists = await File(iosSimulateSDKFile).exists();

  if (!exists) {
    await downloadFile(
        Uri.parse('https://www.dropbox.com/s/evz0upul4mp99ic/MobileRTC?dl=0'),
        iosSimulateSDKFile);
  }

  var androidCommonLibFile = location + '/android/libs/commonlib.aar';
  exists = await File(androidCommonLibFile).exists();
  if (!exists) {
    await downloadFile(
        Uri.parse(
            'https://www.dropbox.com/s/lcjoc2evrmeucte/commonlib.aar?dl=1'),
        androidCommonLibFile);
  }
  var androidRTCLibFile = location + '/android/libs/mobilertc.aar';
  exists = await File(androidRTCLibFile).exists();
  if (!exists) {
    await downloadFile(
        Uri.parse(
            'https://www.dropbox.com/s/exe1aa0aflyh53f/mobilertc.aar?dl=1'),
        androidRTCLibFile);
  }
}

Future downloadFile(Uri uri, String savePath) async {
  print('Download ${uri.toString()} to $savePath');
  File destinationFile = await File(savePath).create(recursive: true);

  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  await response.pipe(destinationFile.openWrite());
}
