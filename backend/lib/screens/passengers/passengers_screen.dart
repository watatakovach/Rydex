import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class PassengersScreen extends StatefulWidget {
  final String token;

  const PassengersScreen({
    super.key,
    required this.token,
  });

  @override
  State<PassengersScreen> createState() =>
      _PassengersScreenState();
}

class _PassengersScreenState
    extends State<PassengersScreen> {
  List<dynamic> passengers = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPassengers();
  }

  Future<void> loadPassengers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await AdminApiService.getPassengers(
        widget.token,
      );

      if (!mounted) return;

      setState(() {
        passengers = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      body: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Passengers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Manage RYDEX passenger accounts.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                IconButton(
                  tooltip: 'Refresh',
                  onPressed:
                      isLoading
                          ? null
                          : loadPassengers,
                  icon:
                      const Icon(
                    Icons.refresh,
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Expanded(
              child: buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            Text(
              errorMessage!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  loadPassengers,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    if (passengers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey,
            ),

            SizedBox(height: 20),

            Text(
              'No Passengers',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'No passenger accounts have been registered yet.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          loadPassengers,

      child: ListView.builder(
        itemCount:
            passengers.length,

        itemBuilder:
            (context, index) {
          final passenger =
              passengers[index];

          final id =
              passenger['id'];

          final name =
              passenger['full_name'] ??
                  'Unknown';

          final phone =
              passenger[
                      'phone_number'] ??
                  'Not provided';

          final email =
              passenger['email'] ??
                  'Not provided';

          final isActive =
              passenger[
                      'is_active'] ??
                  false;

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 15,
            ),

            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(
                20,
              ),

              leading: CircleAvatar(
                radius: 28,

                child: Text(
                  name
                      .toString()
                      .substring(
                        0,
                        1,
                      )
                      .toUpperCase(),
                ),
              ),

              title: Text(
                name.toString(),

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              subtitle: Padding(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      'Passenger ID: $id',
                    ),

                    Text(
                      'Phone: $phone',
                    ),

                    Text(
                      'Email: $email',
                    ),
                  ],
                ),
              ),

              trailing:
                  Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      isActive
                          ? Colors.green
                              .withOpacity(
                              0.1,
                            )
                          : Colors.red
                              .withOpacity(
                              0.1,
                            ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child: Text(
                  isActive
                      ? 'Active'
                      : 'Inactive',

                  style:
                      TextStyle(
                    color:
                        isActive
                            ? Colors.green
                            : Colors.red,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}