import 'package:flutter/material.dart';
import 'fleet_page.dart';
import 'services/api_service.dart';

void main() => runApp(const RydexAdminApp());

class RydexAdminApp extends StatelessWidget {
  const RydexAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RYDEX Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const AdminLoginPage(),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    try {
      await ApiService.login(username.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RYDEX Admin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Email or phone')),
            TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            FilledButton(onPressed: login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tab == 0 ? 'Pending Drivers' : 'Fleet')),
      body: IndexedStack(
        index: tab,
        children: const [PendingDriversPage(), FleetPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.badge_outlined), label: 'Drivers'),
          NavigationDestination(
              icon: Icon(Icons.directions_car_outlined), label: 'Fleet'),
        ],
      ),
    );
  }
}

class PendingDriversPage extends StatefulWidget {
  const PendingDriversPage({super.key});

  @override
  State<PendingDriversPage> createState() => _PendingDriversPageState();
}

class _PendingDriversPageState extends State<PendingDriversPage> {
  List<dynamic> drivers = [];

  Future<void> load() async {
    try {
      final data = await ApiService.pendingDrivers();
      if (mounted) setState(() => drivers = data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> verify(int id) async {
    await ApiService.verifyDriver(id);
    await load();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (_, i) {
          final d = Map<String, dynamic>.from(drivers[i]);
          return Card(
            child: ListTile(
              title: Text('Driver #${d['id']}'),
              subtitle: Text('License: ${d['license_number']}'),
              trailing: FilledButton(
                onPressed: () => verify(d['id']),
                child: const Text('Verify'),
              ),
            ),
          );
        },
      ),
    );
  }
}
