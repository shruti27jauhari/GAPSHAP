import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'user_profile_notifier.dart';
import 'chat_screen.dart'; // Import ChatScreen
// Needed for FAB navigation

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  late UserProfileNotifier _userProfileNotifier; // Declare notifier

  @override
  void initState() {
    super.initState();
    _userProfileNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
    _userProfileNotifier.addListener(_onUserProfileChanged); // Listen for profile changes
    _fetchGroups();
  }

  @override
  void dispose() {
    _userProfileNotifier.removeListener(_onUserProfileChanged); // Remove listener
    super.dispose();
  }

  void _onUserProfileChanged() {
    // Re-fetch groups when user profile changes (e.g., after login/logout)
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUserId = _userProfileNotifier.userProfile?['id'] ?? supabase.auth.currentUser!.id; // Get current user ID from notifier or fallback
      final List<Map<String, dynamic>> data = await supabase
          .from('group_members')
          .select('group_id, groups(name)')
          .eq('user_id', currentUserId);

      List<Map<String, dynamic>> fetchedGroups = [];
      for (var row in data) {
        if (row['groups'] != null) {
          fetchedGroups.add({
            'id': row['group_id'],
            'name': row['groups']['name'],
          });
        }
      }

      setState(() {
        _groups = fetchedGroups;
      });
    } catch (e) {
      print('Error fetching groups: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching groups: $e'),
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
      floatingActionButton: null, // Removed FloatingActionButton
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    title: Text(group['name'] ?? 'Unknown Group'),
                    subtitle: const Text('Group chat'),
                    trailing: const Text(''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: group['id'],
                            isGroupChat: true,
                            receiverId: null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
