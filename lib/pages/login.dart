import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth.dart';
import '../providers/profiles.dart';

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _formKey = GlobalKey<FormState>();

final _displayNameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

final AuthService _authService = AuthService();

bool _isLoginMode = false;
bool _isLoading = false;
bool _isResettingPassword = false;

@override
void initState() {
super.initState();

final session = Supabase.instance.client.auth.currentSession;

if (session != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.go('/');
  });
}

}

@override
void dispose() {
_displayNameController.dispose();
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

void _toggleMode() {
setState(() {
_isLoginMode = !_isLoginMode;
_displayNameController.clear();
});
}

Future<void> _forgotPassword() async {
final emailController = TextEditingController(
text: _emailController.text.trim(),
);

final email = await showDialog<String>(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Forgot password?'),
      content: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = emailController.text.trim();

            if (value.isEmpty || !value.contains('@')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enter a valid email address.'),
                ),
              );
              return;
            }

            Navigator.pop(context, value);
          },
          child: const Text('Send reset link'),
        ),
      ],
    );
  },
);

emailController.dispose();

if (email == null || email.isEmpty) return;

setState(() => _isResettingPassword = true);

try {
  await Supabase.instance.client.auth.resetPasswordForEmail(
    email,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Password reset link sent. Check your email.',
      ),
    ),
  );
} on AuthException catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed to send reset link: $e'),
    ),
  );
} finally {
  if (mounted) {
    setState(() => _isResettingPassword = false);
  }
}

}

Future<void> _submit() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

final displayName = _displayNameController.text.trim();
final email = _emailController.text.trim();
final password = _passwordController.text.trim();

try {
  if (_isLoginMode) {
    await _authService.signIn(
      email: email,
      password: password,
    );

    await ProfileService.instance.loadCurrentProfile();

    if (!mounted) return;

    context.go('/');
  } else {
    final response = await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (!mounted) return;

    final message = response.session != null
        ? 'Registration successful. You are signed in.'
        : 'Registration successful. Please check your email to confirm.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(message)),
    );

    await _authService.signIn(
      email: email,
      password: password,
    );

    await ProfileService.instance.loadCurrentProfile();

    if (response.session != null) {
      context.go('/');
    }
  }
} on AuthException catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    SnackBar(
      content: Text('Authentication failed: $e'),
    ),
  );
} finally {
  if (mounted) {
    setState(() => _isLoading = false);
  }
}

}

String? _validateDisplayName(String? value) {
if (!_isLoginMode) {
if (value == null || value.trim().isEmpty) {
return 'Display name is required';
}

  if (value.trim().length < 3) {
    return 'Display name must be at least 3 characters';
  }
}

return null;

}

String? _validateEmail(String? value) {
if (value == null || value.isEmpty) {
return 'Email is required';
}

if (!value.contains('@')) {
  return 'Enter a valid email';
}

return null;

}

String? _validatePassword(String? value) {
if (value == null || value.isEmpty) {
return 'Password is required';
}

if (value.length < 6) {
  return 'Password must be at least 6 characters';
}

return null;

}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Padding(
padding: const EdgeInsets.all(24),
child: Center(
child: SingleChildScrollView(
child: Card(
elevation: 4,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 24,
),
child: Form(
key: _formKey,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
_isLoginMode
? 'Sign in with your email and password'
: 'Create a new account',
textAlign: TextAlign.center,
style: Theme.of(context).textTheme.bodyLarge,
),

                  const SizedBox(height: 24),

                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: _validateDisplayName,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _validateEmail,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: _validatePassword,
                  ),

                  if (_isLoginMode) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: (_isLoading || _isResettingPassword)
                            ? null
                            : _forgotPassword,
                        child: _isResettingPassword
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Forgot password?'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Login' : 'Register',
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(
                      _isLoginMode
                          ? 'Create a new account'
                          : 'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);


}
}
