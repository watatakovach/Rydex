import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() => runApp(const RydexPassengerApp());

class RydexPassengerApp extends StatelessWidget {
  const RydexPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RYDEX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const PassengerLoginPage(),
    );
  }
}

class PassengerLoginPage extends StatefulWidget {
  const PassengerLoginPage({super.key});

  @override
  State<PassengerLoginPage> createState() => _PassengerLoginPageState();
}

class _PassengerLoginPageState extends State<PassengerLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    try {
      await ApiService.login(username.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassengerHomePage()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RYDEX')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: username, decoration: const InputDecoration(labelText: 'Email or phone')),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            FilledButton(onPressed: login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  final pickup = TextEditingController();
  final destination = TextEditingController();
  String message = '';

  Future<void> requestRide() async {
    try {
      final ride = await ApiService.requestRide(
        pickup: pickup.text.trim(),
        destination: destination.text.trim(),
      );
      setState(() => message = 'Ride #${ride['id']} requested.');
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RYDEX Passenger')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: pickup, decoration: const InputDecoration(labelText: 'Pickup')),
            TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination')),
            const SizedBox(height: 20),
            FilledButton(onPressed: requestRide, child: const Text('Request Ride')),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}
