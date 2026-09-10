import 'package:flutter/material.dart';


import '../../core/services/api_service.dart';
// import '../home/driver_home_screen.dart';
import 'verification_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({
    super.key,
  });

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _licenseController =
      TextEditingController();

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
      await ApiService.registerDriver(
        licenseNumber:
            _licenseController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Driver registration submitted successfully.',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const VerificationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Registration',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 20,
                ),

                const Icon(
                  Icons
                      .verified_user_outlined,
                  size: 80,
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Become a RydeX Driver',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  'Enter your driving license number to start your driver registration.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey[600],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                TextFormField(
                  controller:
                      _licenseController,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Driving License Number',
                    hintText:
                        'e.g. DL12345678',
                    prefixIcon:
                        Icon(Icons.badge),
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

                const SizedBox(
                  height: 20,
                ),

                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    color: Colors.orange
                        .withValues(
                      alpha: 0.1,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                            Colors.orange,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          'Your driver account will remain pending until the RydeX administration team verifies your information.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                SizedBox(
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _registerDriver,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SUBMIT REGISTRATION',
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