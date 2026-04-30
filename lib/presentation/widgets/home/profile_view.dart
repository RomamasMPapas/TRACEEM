import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../screens/login_screen.dart';

/// A premium user profile panel for editing details with high-end UI design.
class ProfileView extends StatefulWidget {
  final UserEntity user;

  const ProfileView({super.key, required this.user});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

/// The [_ProfileViewState] class is responsible for managing its respective UI components and state.
class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _passwordController;

  /// Initializes the state of the widget before it is built.
  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _passwordController = TextEditingController();
  }

  /// Cleans up resources when the widget is permanently removed from the tree.
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Executes the logic for _updateProfile.
  void _updateProfile() {
    context.read<AuthBloc>().add(
      UpdateProfileSubmitted(
        id: widget.user.id,
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
        photoUrl: widget.user.photoUrl,
      ),
    );
  }

  /// Shows a dialog to enter a new photo URL.
  void _showPhotoUrlDialog() {
    final TextEditingController urlController =
        TextEditingController(text: widget.user.photoUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a direct image URL (e.g., from an image hosting site) to permanently update your profile picture.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/image.png',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(
                    UpdateProfileSubmitted(
                      id: widget.user.id,
                      fullName: _fullNameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      phoneNumber: _phoneNumberController.text,
                      address: _addressController.text,
                      photoUrl: urlController.text.trim().isEmpty
                          ? null
                          : urlController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C8CFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('UPDATE PHOTO'),
          ),
        ],
      ),
    );
  }

  /// Builds the visual structure of this widget, returning the widget tree.
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Column(
        children: [
          // High-end Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF4C8CFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _showPhotoUrlDialog,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            widget.user.photoUrl ??
                                'https://robohash.org/${widget.user.username}?set=set4',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 60, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPhotoUrlDialog,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4C8CFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  widget.user.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Settings Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildPremiumField(
                    label: "Full Name",
                    controller: _fullNameController,
                    icon: Icons.person_outline,
                    hintText: "Enter your full name",
                  ),
                  _buildPremiumField(
                    label: "Email Address",
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hintText: "Enter your email",
                  ),
                  _buildPremiumField(
                    label: "Phone Number",
                    controller: _phoneNumberController,
                    icon: Icons.phone_outlined,
                    hintText: "+63 9...",
                  ),
                  _buildPremiumField(
                    label: "Home Address",
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    hintText: "Enter your complete address",
                  ),
                  _buildPremiumField(
                    label: "Update Password",
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hintText: "Leave blank to keep current password",
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C8CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFF4C8CFF).withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        "SAVE CHANGES",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(icon, color: const Color(0xFF4C8CFF), size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
