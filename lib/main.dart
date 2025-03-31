// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class Fish {
  Color color;
  double speed;

  Fish({required this.color, required this.speed});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AquariumScreen());
  }
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    Database db = await openDatabase(
      join(await getDatabasesPath(), 'settings.db'),
    );
    List<Map> result = await db.query('settings');
    if (result.isNotEmpty) {
      setState(() {
        selectedColor = Color(result[0]['color'] ?? Colors.blue.value);
        selectedSpeed = result[0]['speed']?.toDouble() ?? 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.lightBlue[50],
            child: Stack(
              children:
                  fishList.map<Widget>((fish) {
                    return AnimatedFish(fish: fish);
                  }).toList(),
            ),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Settings'),
              ),
            ],
          ),
          Row(
            children: [
              Slider(
                value: selectedSpeed,
                min: 0.1,
                max: 5.0,
                divisions: 50,
                label: selectedSpeed.toString(),
                onChanged: (value) {
                  setState(() {
                    selectedSpeed = value;
                  });
                },
              ),
              DropdownButton<Color>(
                value: selectedColor,
                items: [
                  DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                  DropdownMenuItem(value: Colors.red, child: Text('Red')),
                  DropdownMenuItem(value: Colors.green, child: Text('Green')),
                ],
                onChanged: (color) {
                  setState(() {
                    selectedColor = color!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _saveSettings() async {
    Database db = await openDatabase(
      join(await getDatabasesPath(), 'settings.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, color INTEGER, speed REAL)',
        );
      },
    );

    await db.insert('settings', {
      'color': selectedColor.value,
      'speed': selectedSpeed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class AnimatedFish extends StatefulWidget {
  final Fish fish;
  const AnimatedFish({super.key, required this.fish});

  @override
  State<AnimatedFish> createState() => _AnimatedFishState();
}

class _AnimatedFishState extends State<AnimatedFish>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _fishMovement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _fishMovement = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1.5, 1.5),
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fishMovement,
      builder: (context, child) {
        return Positioned(
          left: 100.0 * _fishMovement.value.dx,
          top: 100.0 * _fishMovement.value.dy,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.fish.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
