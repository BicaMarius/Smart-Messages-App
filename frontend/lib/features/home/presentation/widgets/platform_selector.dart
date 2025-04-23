import 'package:flutter/material.dart';
import 'package:frontend/features/home/domain/models/social_media_platform.dart';

class PlatformSelector extends StatelessWidget {
  final List<SocialMediaPlatform> platforms;
  final Function(SocialMediaPlatform) onPlatformSelected;

  const PlatformSelector({
    super.key,
    required this.platforms,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        itemBuilder: (context, index) {
          final platform = platforms[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () => onPlatformSelected(platform),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    platform.icon,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    platform.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 