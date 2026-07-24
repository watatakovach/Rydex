import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/driver.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({
    super.key,
  });

  @override
  State<DriverRegisterScreen> createState() =>
      _DriverRegisterScreenState();
}

class _DriverRegisterScreenState
    extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Driver driver =
          await ApiService.registerDriver(
        licenseNumber:
            _licenseController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Your profile is awaiting verification.',
          ),
        ),
      );

      Navigator.pop(context, driver);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                const Icon(
                  Icons.local_taxi,
                  size: 80,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Become a RydeX Driver',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Register your driver profile to begin the verification process.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller:
                      _licenseController,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Driver License Number',
                    hintText:
                        'DL12345678',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter your license number';
                    }

                    if (value.trim().length <
                        5) {
                      return 'License number is too short';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _registerDriver,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(),
                          )
                        : const Text(
                            'Register as Driver',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}