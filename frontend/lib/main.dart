import 'package:flutter/material.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/domain/models/social_media_platform.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Messages App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Global Gesture Detector to close keyboard on tap
       builder: (BuildContext context, Widget? child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: child,
        );
      },
      home: HomePage(platformColor: SocialMediaPlatform.platforms[0].iconColor),
    );
  }
}
