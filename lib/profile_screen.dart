import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart'; // New import
import 'package:gapshap/user_profile_notifier.dart'; // New import

import 'package:gapshap/widgets/custom_text_field.dart';
import 'package:gapshap/widgets/custom_button.dart';
import 'package:gapshap/settings_screen.dart'; // Import settings screen

class ProfileScreen extends StatefulWidget {
  final String? userId; // Make userId optional

  const ProfileScreen({super.key, this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isEditingDisplayName = false;
  bool _isEditingAbout = false;
  bool _isEditingUsername = false;

  @override
  void initState() {
    super.initState();
    print('ProfileScreen: initState called.');
    // Trigger loading of user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProfileNotifier>(context, listen: false).loadUserProfile(userId: widget.userId);
    });
  }

  // Removed _fetchProfile as it's now handled by UserProfileNotifier

  Future<void> _updateProfileField(String fieldName, String value) async {
    final userProfileNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
    await userProfileNotifier.updateProfileField(fieldName, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${fieldName.replaceAll('_', ' ').capitalize()} updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}-${pickedFile.name}';
      const bucketName = 'avatars'; // Assuming a bucket named 'avatars' in Supabase Storage

      try {
        final String path = await supabase.storage.from(bucketName).upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        final String publicUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

        final userProfileNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
        await userProfileNotifier.updateAvatarUrl(publicUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error uploading profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onLogout() async {
    // _isLoading is managed by UserProfileNotifier, but logout is a separate action
    try {
      await supabase.auth.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileScreen: build method called.');
    return Consumer<UserProfileNotifier>(
      builder: (context, userProfileNotifier, child) {
        final userProfile = userProfileNotifier.userProfile;
        final isLoading = userProfileNotifier.isLoading;

        print('ProfileScreen: Consumer rebuilding. isLoading: $isLoading, userProfile: $userProfile');

        // Update controllers only if the text has actually changed to avoid cursor issues
        if (userProfile != null) {
          if (_displayNameController.text != (userProfile['username'] ?? '')) {
            _displayNameController.text = userProfile['username'] ?? '';
            print('ProfileScreen: _displayNameController updated to: ${_displayNameController.text}');
          }
          if (_aboutController.text != (userProfile['about'] ?? 'Hey there! I am using ChatX')) {
            _aboutController.text = userProfile['about'] ?? 'Hey there! I am using ChatX';
            print('ProfileScreen: _aboutController updated to: ${_aboutController.text}');
          }
          if (_usernameController.text != (userProfile['username_handle'] ?? userProfile['username'] ?? '')) {
            _usernameController.text = userProfile['username_handle'] ?? userProfile['username'] ?? '';
            print('ProfileScreen: _usernameController updated to: ${_usernameController.text}');
          }
        } else {
          print('ProfileScreen: userProfile is null.');
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage: userProfile?['avatar_url'] != null
                                    ? NetworkImage(userProfile!['avatar_url'])
                                    : null,
                                child: userProfile?['avatar_url'] == null
                                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: Theme.of(context).hintColor,
                                  radius: 20,
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileField(
                        'Display Name',
                        _displayNameController,
                        _isEditingDisplayName,
                        () {
                          setState(() {
                            _isEditingDisplayName = !_isEditingDisplayName;
                          });
                          if (!_isEditingDisplayName) {
                            _updateProfileField('username', _displayNameController.text);
                          }
                        },
                        maxLength: 25,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        'About',
                        _aboutController,
                        _isEditingAbout,
                        () {
                          setState(() {
                            _isEditingAbout = !_isEditingAbout;
                          });
                          if (!_isEditingAbout) {
                            _updateProfileField('about', _aboutController.text);
                          }
                        },
                        maxLength: 140,
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        'Phone Number',
                        TextEditingController(text: userProfile?['phone_number'] ?? 'N/A'),
                        false, // Not editable
                        null,
                        readOnly: true,
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildProfileField(
                        'Username',
                        _usernameController,
                        _isEditingUsername,
                        () {
                          setState(() {
                            _isEditingUsername = !_isEditingUsername;
                          });
                          if (!_isEditingUsername) {
                            _updateProfileField('username_handle', _usernameController.text); // Assuming a 'username_handle' field
                          }
                        },
                        icon: Icons.alternate_email,
                        hintText: '@username',
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.settings_outlined, color: Theme.of(context).primaryColor),
                          title: const Text('Settings'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: CustomButton(
                          text: isLoading ? 'Loading...' : 'Logout',
                          onPressed: isLoading ? null : () async { await _onLogout(); },
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileField(
    String title,
    TextEditingController controller,
    bool isEditing,
    VoidCallback? onEditPressed, {
    int? maxLength,
    bool readOnly = false,
    IconData? icon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? CustomTextField(
                      controller: controller,
                      labelText: '',
                      prefixIcon: icon,
                      maxLength: maxLength,
                      readOnly: readOnly,
                      hintText: hintText,
                      validator: (value) {
                        if (title == 'Display Name' && (value == null || value.isEmpty)) {
                          return 'Display Name cannot be empty';
                        }
                        if (title == 'Display Name' && value!.length > 25) {
                          return 'Display Name cannot exceed 25 characters';
                        }
                        if (title == 'About' && value!.length > 140) {
                          return 'About cannot exceed 140 characters';
                        }
                        return null;
                      },
                    )
                  : Text(
                      controller.text.isEmpty
                          ? (title == 'About' ? 'Hey there! I am using ChatX' : 'N/A') // Default for Display Name/Username
                          : controller.text,
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
            if (onEditPressed != null)
              IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit),
                onPressed: onEditPressed,
              ),
          ],
        ),
        if (maxLength != null && isEditing)
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
