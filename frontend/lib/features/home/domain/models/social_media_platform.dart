import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialMediaPlatform {
  final String name;
  final IconData icon;
  final Color iconColor;

  SocialMediaPlatform({
    required this.name,
    required this.icon,
    required this.iconColor,
  });

  static List<SocialMediaPlatform> get platforms => [
    SocialMediaPlatform(
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      iconColor: Colors.pinkAccent,
    ),
    SocialMediaPlatform(
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      iconColor: Colors.green,
    ),
    SocialMediaPlatform(
      name: 'Messenger',
      icon: FontAwesomeIcons.facebookMessenger,
      iconColor: Colors.blue,
    ),
  ];
} 