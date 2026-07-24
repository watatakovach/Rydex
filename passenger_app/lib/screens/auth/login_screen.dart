import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../passenger/home_screen.dart';
// import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

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

  // ==========================================
  // LOGIN
  // ==========================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful'),
          backgroundColor: Colors.green,
        ),
      );

      // ==========================================
      // GO TO HOME SCREEN
      // ==========================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
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
          backgroundColor: Colors.red,
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

  // ==========================================
  // EMAIL VALIDATION
  // ==========================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 20,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    // ==================================
                    // LOGO
                    // ==================================

                    const Icon(
                      Icons.local_taxi,
                      size: 80,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'RYDEX',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Ride Smarter',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 45),

                    // ==================================
                    // TITLE
                    // ==================================

                    const Text(
                      'Welcome Back',

                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Login to continue',

                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================
                    // EMAIL
                    // ==================================

                    TextFormField(
                      controller: _emailController,

                      keyboardType:
                          TextInputType.emailAddress,

                      validator: _validateEmail,

                      decoration: InputDecoration(
                        labelText: 'Email',

                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ),

                        filled: true,

                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================
                    // PASSWORD
                    // ==================================

                    TextFormField(
                      controller:
                          _passwordController,

                      obscureText:
                          _obscurePassword,

                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your password';
                        }

                        if (value.length < 6) {
                          return 'Password is too short';
                        }

                        return null;
                      },

                      decoration: InputDecoration(
                        labelText: 'Password',

                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),

                        filled: true,

                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),

                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    // ==================================
                    // FORGOT PASSWORD
                    // ==================================

                    Align(
                      alignment:
                          Alignment.centerRight,

                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger
                              .of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Forgot Password coming soon.',
                              ),
                            ),
                          );
                        },

                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================
                    // LOGIN BUTTON
                    // ==================================

                    SizedBox(
                      height: 55,

                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _login,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green,

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                                width: 26,
                                height: 26,

                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,

                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'LOGIN',

                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================
                    // REGISTER
                    // ==================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Text(
                          "Don't have an account?",
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/register',
                            );
                          },

                          child: const Text(
                            'Register',

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}