import 'package:flutter/material.dart';
import 'package:bikebooking/features/location/presentation/pages/select_location_screen.dart';
import 'package:bikebooking/features/location/presentation/pages/select_state_screen.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectLocationScreen()),
                );
              },
              child: Text('Go to Select Location'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectStateScreen()),
                );
              },
              child: Text('Go to Select State (Direct)'),
            ),
          ],
        ),
      ),
    );
  }
}
