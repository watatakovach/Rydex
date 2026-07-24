import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Today's Earnings",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'KES 0.00',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.payments_outlined,
              ),
              title: const Text(
                'Total Earnings',
              ),
              trailing: const Text(
                'KES 0.00',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.directions_car_outlined,
              ),
              title: const Text(
                'Completed Rides',
              ),
              trailing: const Text(
                '0',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today_outlined,
              ),
              title: const Text(
                'This Week',
              ),
              trailing: const Text(
                'KES 0.00',
              ),
            ),
          ),
        ],
      ),
    );
  }
}