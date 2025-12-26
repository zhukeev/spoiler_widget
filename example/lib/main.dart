import 'package:flutter/material.dart';
import 'pages/spoiler_overlay_page.dart';
import 'pages/spoiler_performance_page.dart';
import 'pages/spoiler_text_field_page.dart';
import 'pages/spoiler_text_page.dart';
import 'pages/spoiler_text_wrapper_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      showPerformanceOverlay: false,
      home: _DemoListPage(),
    );
  }
}

class _DemoListPage extends StatelessWidget {
  const _DemoListPage();

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoEntry>[
      _DemoEntry('SpoilerText', () => const SpoilerTextPage()),
      _DemoEntry('SpoilerTextField', () => const SpoilerTextFieldPage()),
      _DemoEntry('SpoilerTextWrapper', () => const SpoilerTextWrapperPage()),
      _DemoEntry('SpoilerOverlay', () => const SpoilerOverlayPage()),
      _DemoEntry('SpoilerOverlay Full',
          () => const SpoilerOverlayPage(fullPage: true)),
      _DemoEntry('Performance', () => const SpoilerPerformancePage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Spoiler Widget Demos')),
      backgroundColor: Colors.white,
      body: ListView.separated(
        itemCount: demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            title: Text(demo.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => demo.builder()),
              );
            },
          );
        },
      ),
    );
  }
}

class _DemoEntry {
  _DemoEntry(this.title, this.builder);
  final String title;
  final Widget Function() builder;
}
