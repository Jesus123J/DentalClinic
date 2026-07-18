import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initFfi();
  runApp(const DentalClinicApp());
}
