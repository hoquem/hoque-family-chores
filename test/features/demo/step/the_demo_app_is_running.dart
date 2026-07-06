import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple counter widget for demonstrating BDD tests
class DemoCounterWidget extends StatefulWidget {
  const DemoCounterWidget({super.key});

  @override
  State<DemoCounterWidget> createState() => _DemoCounterWidgetState();
}

class _DemoCounterWidgetState extends State<DemoCounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BDD Demo')),
        body: Center(
          child: Text(
            '$_counter',
            style: const TextStyle(fontSize: 48),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Usage: the demo app is running
Future<void> theDemoAppIsRunning(WidgetTester tester) async {
  await tester.pumpWidget(const DemoCounterWidget());
}
