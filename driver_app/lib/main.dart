import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const RydexDriverApp());
}

class RydexDriverApp extends StatelessWidget {
  const RydexDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RYDEX Driver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const DriverLoginPage(),
    );
  }
}

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      await ApiService.login(username.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RYDEX Driver')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: username, decoration: const InputDecoration(labelText: 'Email or phone')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : login,
              child: Text(loading ? 'Signing in...' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  Map<String, dynamic>? profile;
  bool loading = true;

  Future<void> load() async {
    try {
      final result = await ApiService.profile();
      if (mounted) setState(() => profile = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggle(bool value) async {
    try {
      final result = await ApiService.status(value);
      if (mounted) setState(() => profile = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final verified = profile?['is_verified'] == true;
    final online = profile?['is_online'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('RYDEX Driver')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                title: const Text('Verification Status'),
                subtitle: Text(verified ? 'Verified' : 'Verification pending'),
                leading: Icon(verified ? Icons.verified : Icons.pending),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: Text(online ? 'You are Online' : 'You are Offline'),
                subtitle: Text(verified ? 'Go online to receive rides' : 'Verification is required before going online'),
                value: online,
                onChanged: verified ? toggle : null,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('License'),
                subtitle: Text(profile?['license_number'] ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
