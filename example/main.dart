import 'package:easy_dio_client/src/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:easy_dio_client/easy_dio_client.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.init(
    baseUrl: "https://reqres.in/api",
    refreshTokenEndpoint: "/refresh",
    refreshTokenEndpointKey: "refresh_token",
    accessTokenKey: "access_token",
    refreshTokenKey: "refresh_token",
    onAuthFailure: () {
      debugPrint("Auth failed");
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const SplashScreen());
  }
}
