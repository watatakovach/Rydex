// import 'package:driver_app/screens/verification/document_upload_screen.dart';
import 'package:flutter/material.dart';
// import 'document_upload_screen.dart';
import '../verification/document_upload_screen.dart';

import '../../core/services/api_service.dart';



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
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _licenseController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  // ============================================================
  // REGISTER DRIVER
  // ============================================================

  Future<void> _registerDriver() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent duplicate requests
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Register driver using logged-in user's token
      await ApiService.registerDriver(
        licenseNumber:
            _licenseController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver registration successful. Your account is awaiting verification.',
          ),
        ),
      );

      // Go back to Driver Home Screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DocumentUploadScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final errorMessage = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register as Driver',
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

                // ==================================================
                // ICON
                // ==================================================

                const Icon(
                  Icons.local_taxi,
                  size: 80,
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Become a RydeX Driver',

                  textAlign:
                      TextAlign.center,

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                Text(
                  'Register your driver profile to start driving with RydeX.',

                  textAlign:
                      TextAlign.center,

                  style: TextStyle(
                    fontSize: 16,
                    color:
                        Colors.grey[600],
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                // ==================================================
                // LICENSE NUMBER
                // ==================================================

                TextFormField(
                  controller:
                      _licenseController,

                  enabled:
                      !_isLoading,

                  textInputAction:
                      TextInputAction.done,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Driving License Number',

                    hintText:
                        'Enter your license number',

                    prefixIcon:
                        Icon(
                      Icons.badge_outlined,
                    ),

                    border:
                        OutlineInputBorder(),
                  ),

                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter your license number';
                    }

                    if (value
                            .trim()
                            .length <
                        3) {
                      return 'Please enter a valid license number';
                    }

                    return null;
                  },

                  onFieldSubmitted:
                      (_) {
                    if (!_isLoading) {
                      _registerDriver();
                    }
                  },
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // INFORMATION CARD
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Icon(
                          Icons.info_outline,
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Text(
                            'After registration, your driver account will be reviewed by RydeX. You will be able to go online and receive rides after your account has been verified.',

                            style:
                                TextStyle(
                              color:
                                  Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                // ==================================================
                // REGISTER BUTTON
                // ==================================================

                SizedBox(
                  height: 52,

                  child:
                      ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _registerDriver,

                    child:
                        _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Text(
                                'REGISTER AS DRIVER',

                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
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