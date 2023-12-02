import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';

class Config {
  static const unsplashAccessKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY',
      defaultValue: 'u_pan7tFV-qTFs2RLImY-wYedRrffIc-kM1azrdhYBI');
  static const unsplashSecretKey = String.fromEnvironment('UNSPLASH_SECRET_KEY',
      defaultValue: 'R18lB-pUThjWWW1tLWirZsBd0p7t5qAadebY-tyrlX4');
}


const cacheSize200M = 200 * 1024 * 1024;
void setStatusBarColor() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withOpacity(0.002)));
}
