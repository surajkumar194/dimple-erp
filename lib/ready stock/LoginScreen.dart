import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:dimple_erp/all screen/MainScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  // ================= LOGIN FUNCTION =================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Save login time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'loginTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );

      _showSnackBar("Login successful!");

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed. Please try again.";

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage =
              "Too many attempts. Please try again later.";
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      _passwordController.clear();
      _showSnackBar(errorMessage, isError: true);

    } catch (e) {
      _showSnackBar(
        "Something went wrong. Please try again.",
        isError: true,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ================= SNACKBAR =================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(5.w),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 254, 252),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 5.w,
                      right: 5.w,
                      top: 6.h,
                      bottom: 3.h,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.sp),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 3.h,
                        ),
                        child: Column(
                          children: [
                            Image.asset('assets/logo.png', height: 22.h),

                            Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1e3a8a),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              "Sign in to continue",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 3.h),

                            // ================= EMAIL =================
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF1e3a8a),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1e3a8a),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter email";
                                }
                                if (!value.contains('@')) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 3.h),

                            // ================= PASSWORD =================
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF1e3a8a),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1e3a8a),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter password";
                                }
                                if (value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 5.h),

                            // ================= LOGIN BUTTON =================
                            SizedBox(
                              width: double.infinity,
                              height: 6.5.h,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF1e3a8a),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            SizedBox(height: 3.h),

                            Text(
                              "Dimple Packaging Pvt. Ltd.",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1e3a8a),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              "© 2025 All Rights Reserved",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
