import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import 'driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.loginDriver(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const DriverHomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RydeX Driver',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 450,
              ),
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
                    'Driver Login',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  TextField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Password',
                      prefixIcon:
                          const Icon(
                        Icons.lock,
                      ),
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
                      border:
                          const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
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