import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // validating the form and signing in
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final successful = await authProvider.signIn(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (!successful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Unable to sign in.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // main.dart opens the dashboard after successful login
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // showing the coral background shape
          Positioned(
            top: 80,
            left: -65,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: coral.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // showing the mint background shape
          Positioned(
            bottom: -60,
            right: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: mint.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // showing the CampusFire logo
                    Image.asset(
                      'assets/images/campusfire_logo.png',
                      height: 125,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_fire_department,
                          color: coral,
                          size: 90,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: navy,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // showing the login message
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Login to report a fire',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.sentiment_satisfied_alt,
                          color: coral,
                          size: 21,
                        ),
                        Text(
                          '!',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // showing the login form card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withValues(alpha: 0.10),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign in to your account',
                              style: TextStyle(
                                color: navy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // entering the campus email
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'ALU email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE3E8EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: coral,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Enter your Student email.';
                                }

                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  return 'Enter a valid email address.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // entering the password
                            TextFormField(
                              controller: passwordController,
                              obscureText: hidePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!authProvider.isLoading) {
                                  signIn();
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                filled: true,
                                fillColor: background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE3E8EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: coral,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password.';
                                }

                                if (value.length < 6) {
                                  return 'Password must have at least 6 characters.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // signing into CampusFire
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: coral,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: coral.withValues(
                                    alpha: 0.55,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // opening the signup page
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: coral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // showing the security message
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: mint, size: 17),
                        SizedBox(width: 6),
                        Text(
                          'Your reports are handled securely.',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
