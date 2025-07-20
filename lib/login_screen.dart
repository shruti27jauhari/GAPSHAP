import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gapshap/widgets/custom_text_field.dart';
import 'package:gapshap/widgets/custom_button.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter

import 'signup_screen.dart'; // Ensure SignupScreen is imported

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Add a form key
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // New controller for phone number
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose(); // Dispose new controller
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showResendEmailDialog() async {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Verification Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to resend the verification email:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await Supabase.instance.client.auth.resend(
                    type: OtpType.signup,
                    email: emailController.text,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent! Check your inbox and spam folder.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final String email = _emailController.text.trim();
      final String phone = _phoneController.text.trim();
      final String password = _passwordController.text;

      if (email.isNotEmpty) {
        // Prioritize email login
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else if (phone.isNotEmpty) {
        // Fallback to phone login if email is empty
        // Note: signInWithPassword does not support phone directly.
        // For phone login, you'd typically use signInWithOtp and then verify OTP.
        // If you want password-based login with phone, Supabase needs to be configured for it.
        // For now, we'll use signInWithOtp for phone, which requires OTP verification.
        await Supabase.instance.client.auth.signInWithOtp(
          phone: phone,
          // You might need to add a redirect URL if using deep links for OTP verification
          // emailRedirectTo: 'YOUR_DEEPLINK_URL',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your phone! Please verify.'),
            backgroundColor: Colors.blue,
          ),
        );
        // After sending OTP, you would typically navigate to an OTP verification screen.
        // For this implementation, we'll just show the snackbar.
        // The user will need to manually verify the OTP.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter either email or phone number.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onLoginSuccess(); // Only call on success
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form( // Wrap with Form widget
            key: _formKey, // Assign form key
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Login to continue your chat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email (Optional)',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_emailController.text.isEmpty && _phoneController.text.isEmpty) {
                      return 'Enter email or phone number';
                    }
                    if (_emailController.text.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits
                  validator: (value) {
                    if (_emailController.text.isEmpty && _phoneController.text.isEmpty) {
                      return 'Enter email or phone number';
                    }
                    if (_phoneController.text.isNotEmpty && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value!)) {
                      return 'Enter a valid phone number (e.g., +1234567890)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: _isLoading ? 'Loading...' : 'Login',
                  onPressed: _isLoading ? null : () => _signIn(),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _showResendEmailDialog(),
                  child: Text(
                    'Didn\'t receive verification email?',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
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
