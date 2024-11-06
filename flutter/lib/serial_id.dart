import 'package:shared_preferences/shared_preferences.dart';

Future<int?> getSerialId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('serial_id'); // returns null if serial_id is not set
}
