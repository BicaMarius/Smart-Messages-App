import 'package:flutter/material.dart';
import 'package:frontend/features/home/domain/models/social_media_platform.dart';
import 'package:frontend/features/home/presentation/widgets/platform_selector.dart';
import 'package:frontend/features/home/presentation/widgets/event_list.dart';
import 'package:frontend/features/summary/presentation/screens/advanced_summary_screen.dart';
import 'package:frontend/features/ask_ai/presentation/screens/ask_ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TO DO: Implement settings
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          // Home Tab
          Column(
            children: [
              PlatformSelector(
                platforms: SocialMediaPlatform.platforms,
                onPlatformSelected: (platform) {
                  // TO DO: Handle platform selection
                },
              ),
              Expanded(
                child: EventList(
                  events: const [], // TO DO: Pass actual events
                  onEventTap: (event) {
                    // TO DO: Handle event tap
                  },
                ),
              ),
            ],
          ),
          // Summary Tab
          const AdvancedSummaryScreen(),
          // Ask AI Tab
          const AskAIScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Ask AI',
          ),
        ],
      ),
    );
  }
} 