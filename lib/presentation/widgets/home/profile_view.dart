import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../screens/login_screen.dart';

class ProfileView extends StatefulWidget {
  final UserEntity user;

  const ProfileView({super.key, required this.user});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address);
    _phoneNumberController = TextEditingController(
      text: widget.user.phoneNumber,
    );
    _passwordController =
        TextEditingController(); // Password is not pre-filled for security
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    context.read<AuthBloc>().add(
      UpdateProfileSubmitted(
        id: widget.user.id,
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
      ),
    );
  }

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
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Column(
        children: [
          // Blue Header with Profile Icon
          Container(
            width: double.infinity,
            height: 180,
            color: const Color(0xFF4C8CFF),
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 70,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Settings / Form Area
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(
                            Icons.save,
                            size: 18,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            "SAVE CHANGES",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.logout,
                          color: Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildProfileField(
                      "Full Name",
                      "(Can Only Be Change Once)",
                      controller: _fullNameController,
                      showEditIcon: true,
                    ),
                    const SizedBox(height: 25),

                    _buildProfileField(
                      "Address",
                      "Street .................... No./ZIP CODE",
                      controller: _addressController,
                      showStatusIcons: true,
                    ),
                    const SizedBox(height: 25),

                    _buildProfileField(
                      "Email",
                      ".................. @gmail ....................",
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      showStatusIcons: true,
                    ),
                    const SizedBox(height: 25),

                    _buildProfileField(
                      "Number",
                      "(+63) ........................................",
                      controller: _phoneNumberController,
                      showStatusIcons: true,
                    ),
                    const SizedBox(height: 25),

                    _buildProfileField(
                      "Password",
                      "(Can Only Be Change Once A Month)",
                      controller: _passwordController,
                      isPassword: true,
                      showEditIcon: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer with Log Out
          Container(
            width: double.infinity,
            height: 100,
            color: const Color(0xFF4C8CFF),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'LOG OUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String hint, {
    required TextEditingController controller,
    bool isPassword = false,
    bool showEditIcon = false,
    bool showStatusIcons = false,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                const SizedBox(width: 10),
                Icon(prefixIcon, size: 16, color: Colors.grey),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (showEditIcon)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                ),
              if (showStatusIcons) ...[
                const Text(
                  "on",
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                const SizedBox(width: 5),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
