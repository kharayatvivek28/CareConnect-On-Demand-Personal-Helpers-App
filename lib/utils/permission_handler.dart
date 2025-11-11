import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationPermission() async {
  var status = await Permission.location.status;

  if (status.isDenied) {
    status = await Permission.location.request();
  }

  if (status.isGranted) {
    print('Location permission granted.');
    return true;
  } else if (status.isPermanentlyDenied) {
    print(
      'Location permission permanently denied. Please enable it from settings.',
    );
    openAppSettings();
    return false;
  } else {
    print('Location permission denied.');
    return false;
  }
}
