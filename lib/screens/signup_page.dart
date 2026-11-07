import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailUsernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'Student';

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  // getting the email ending from the selected role
  String get emailDomain {
    if (selectedRole == 'Student') {
      return '@alustudent.com';
    }

    return '@alueducation.com';
  }

  // joining the username and email ending
  String get completeEmail {
    return '${emailUsernameController.text.trim()}$emailDomain';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailUsernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // validating the form and creating the account
  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final successful = await authProvider.signUp(
      fullName: nameController.text,
      email: completeEmail,
      password: passwordController.text,
      role: selectedRole,
    );

    if (!mounted) return;

    if (successful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.successMessage!),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Unable to create your account.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            top: 90,
            left: -65,
            child: Container(
              width: 145,
              height: 145,
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
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                color: mint.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              child: Column(
                children: [
                  // showing the back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.arrow_back, color: navy),
                    ),
                  ),

                  // showing the CampusFire logo
                  Image.asset(
                    'assets/images/campusfire_logo.png',
                    height: 105,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_fire_department,
                        color: coral,
                        size: 85,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Create Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: navy,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Join us in keeping the campus safe',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.sentiment_satisfied_alt,
                        color: coral,
                        size: 20,
                      ),
                      Text(
                        '!',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // showing the signup form
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
                            'Create a CampusFire account',
                            style: TextStyle(
                              color: navy,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // entering the full name
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: formDecoration(
                              label: 'Full name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your full name.';
                              }

                              if (value.trim().length < 3) {
                                return 'Enter a valid name.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // selecting the account role
                          DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: formDecoration(
                              label: 'Sign up as',
                              icon: Icons.badge_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Student',
                                child: Text('Student'),
                              ),
                              DropdownMenuItem(
                                value: 'Campus Admin',
                                child: Text('Campus Admin'),
                              ),
                            ],
                            onChanged: authProvider.isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedRole = value;
                                      });
                                    }
                                  },
                          ),

                          const SizedBox(height: 16),

                          // entering only the email username
                          TextFormField(
                            controller: emailUsernameController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration:
                                formDecoration(
                                  label: 'Email username',
                                  icon: Icons.email_outlined,
                                ).copyWith(
                                  hintText: selectedRole == 'Student'
                                      ? 'firstname.lastname'
                                      : 'staff.username',
                                  suffixText: emailDomain,
                                  suffixStyle: const TextStyle(
                                    color: navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            validator: (value) {
                              final username = value?.trim() ?? '';

                              if (username.isEmpty) {
                                return 'Enter your email username.';
                              }

                              if (username.contains('@')) {
                                return 'Enter only the part before @.';
                              }

                              if (username.contains(' ')) {
                                return 'The email cannot contain spaces.';
                              }

                              final validUsername = RegExp(
                                r'^[a-zA-Z0-9._-]+$',
                              );

                              if (!validUsername.hasMatch(username)) {
                                return 'Enter a valid email username.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // showing the complete email address
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: emailUsernameController,
                            builder: (context, value, child) {
                              final username = value.text.trim();

                              if (username.isEmpty) {
                                return const SizedBox();
                              }

                              return Text(
                                'Your email: $username$emailDomain',
                                style: const TextStyle(
                                  color: mint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // entering the password
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.next,
                            decoration:
                                formDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
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
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a password.';
                              }

                              if (value.length < 6) {
                                return 'Password must have at least 6 characters.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // confirming the password
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: hideConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!authProvider.isLoading) {
                                createAccount();
                              }
                            },
                            decoration:
                                formDecoration(
                                  label: 'Confirm password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        hideConfirmPassword =
                                            !hideConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      hideConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm your password.';
                              }

                              if (value != passwordController.text) {
                                return 'The passwords do not match.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // creating the account
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : createAccount,
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
                                        Icon(Icons.person_add_alt_1, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Create Account',
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

                  const SizedBox(height: 20),

                  // returning to the login page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: coral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, color: mint, size: 17),
                      SizedBox(width: 6),
                      Text(
                        'Only verified ALU accounts can register.',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // creating the shared input design
  InputDecoration formDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
