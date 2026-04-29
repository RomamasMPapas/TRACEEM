import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'home_screen.dart';
import 'admin/admin_home_screen.dart';
import '../widgets/curve_painter.dart';
import '../widgets/auth/auth_widgets.dart';

/// The entry screen for unauthenticated users.
/// Handles the landing page, login form, and registration form with animated mode switching.
/// The [LoginScreen] class is responsible for managing its respective UI components and state.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode { landing, login, register }

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // SignUp Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();

  AuthMode _authMode = AuthMode.landing;

  /// Dispatches a [LoginSubmitted] event to [AuthBloc] with the current username and password input.
  /// Executes the logic for _handleLogin.
  void _handleLogin() {
    context.read<AuthBloc>().add(
      LoginSubmitted(_usernameController.text, _passwordController.text),
    );
  }

  /// Dispatches a [SignUpSubmitted] event to [AuthBloc] with the registration form fields.
  /// Executes the logic for _handleRegister.
  void _handleRegister() {
    context.read<AuthBloc>().add(
      SignUpSubmitted(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _signupPasswordController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C8CFF),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final destination = state.user.role == 'admin'
                ? AdminHomeScreen(admin: state.user)
                : HomeScreen(user: state.user);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background Elements (The curve from image)
            Positioned(
              bottom: 100,
              left: -50,
              right: -50,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: CurvePainter(),
              ),
            ),

            // Landing View
            if (_authMode == AuthMode.landing) _buildLandingView(),

            // Modal Forms
            if (_authMode != AuthMode.landing)
              Container(
                color: Colors.black26,
                child: Center(
                  child: _authMode == AuthMode.login
                      ? _buildLoginCard()
                      : _buildRegisterCard(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the initial landing view with the TRACE EM logo and Log In / Sign Up buttons.
  /// Builds and returns the _buildLandingView custom widget component.
  Widget _buildLandingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.local_shipping, size: 120, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'TRACE EM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                buildLandingButton(
                  'LOG IN',
                  const Color(0xFF333333),
                  Colors.white,
                  () => setState(() => _authMode = AuthMode.login),
                ),
                const SizedBox(height: 15),
                buildLandingButton(
                  'SIGN UP',
                  Colors.white,
                  const Color(0xFF333333),
                  () => setState(() => _authMode = AuthMode.register),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the modal login card with username, password fields and social login icons.
  /// Builds and returns the _buildLoginCard custom widget component.
  Widget _buildLoginCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _authMode = AuthMode.landing),
                ),
              ],
            ),
            const Text(
              'LOGIN',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const Divider(thickness: 1, height: 30),
            buildCustomTextField('Username / Email', _usernameController),
            const SizedBox(height: 20),
            buildCustomTextField(
              'Password',
              _passwordController,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: () => _handleLogin(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password logic
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton('LOG IN', _handleLogin),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildSocialIcon(Icons.facebook, Colors.blue), // FB Placeholder
                buildSocialIcon(Icons.email, Colors.red), // Gmail
                buildSocialIcon(
                  Icons.message,
                  Colors.lightBlue,
                ), // Twitter Placeholder
                buildSocialIcon(
                  Icons.camera_alt,
                  Colors.pink,
                ), // Instagram Placeholder
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the modal registration card with full name, email, phone, password and address fields.
  /// Builds and returns the _buildRegisterCard custom widget component.
  Widget _buildRegisterCard() {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() => _authMode = AuthMode.landing),
                  ),
                ],
              ),
              const Text(
                'REGISTER',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Divider(thickness: 1, height: 30),
              buildCustomTextField('Email', _emailController),
              const SizedBox(height: 15),
              buildCustomTextField('Number', _phoneNumberController),
              const SizedBox(height: 15),
              buildCustomTextField(
                'Password',
                _signupPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 15),
              buildCustomTextField('Full Name', _fullNameController),
              const SizedBox(height: 15),
              buildCustomTextField(
                'Address',
                _addressController,
                textInputAction: TextInputAction.done,
                onSubmitted: () => _handleRegister(),
              ),
              const SizedBox(height: 30),
              _buildActionButton('REGISTER', _handleRegister),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a styled action button (e.g. LOG IN or REGISTER) that shows a loading spinner
  /// when the [AuthBloc] is in the loading state.
  /// Builds and returns the _buildActionButton custom widget component.
  Widget _buildActionButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C8CFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            return Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }
}
