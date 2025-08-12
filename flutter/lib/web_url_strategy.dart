// Web platform specific implementation
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void setUrlStrategy() {
  // Use the imported function with a different name to avoid recursion
  usePathUrlStrategy();
}