import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import 'driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.loginUser(
        email:
            _emailController.text.trim(),
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
                  "Exception: ",
                  "",
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

  // ============================================================
  // BUILD
  // ============================================================

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
                children: [
                  // LOGO
                  const Icon(
                    Icons.local_taxi,
                    size: 80,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    "RydeX Driver",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    "Drive with RydeX",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  // EMAIL
                  TextFormField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText: "Email",
                      prefixIcon:
                          Icon(Icons.email),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim()
                              .isEmpty) {
                        return "Enter your email";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // PASSWORD
                  TextFormField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    decoration:
                        InputDecoration(
                      labelText:
                          "Password",
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
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Enter your password";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // LOGIN BUTTON
                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      child:
                          _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  "LOGIN",
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