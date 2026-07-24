import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../home/driver_home_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({
    super.key,
  });

  @override
  State<DriverLoginScreen> createState() =>
      _DriverLoginScreenState();
}

class _DriverLoginScreenState
    extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.loginDriver(
        username:
            _usernameController.text.trim(),
        password:
            _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DriverHomeScreen(),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_taxi,
                    size: 80,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'RydeX Driver',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Sign in to start driving',
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
                        _usernameController,
                    keyboardType:
                        TextInputType.text,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Email or phone number',
                      prefixIcon:
                          Icon(Icons.person),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your email or phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    decoration:
                        InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          const Icon(
                        Icons.lock,
                      ),
                      border:
                          const OutlineInputBorder(),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility
                              : Icons
                                  .visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Enter your password';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
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
                              'LOGIN',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}