import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gapshap/chat_screen.dart'; // Import chat_screen.dart to access ChatScreen

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _profiles = [];
  late final String _currentUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser!.id;
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('profiles')
          .select()
          .neq('id', _currentUserId); // Exclude current user
      setState(() {
        _profiles = data;
      });
    } catch (e) {
      print('Error fetching profiles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching profiles: $e'),
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
      appBar: AppBar(
        title: const Text('New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.group_add, color: Colors.white),
                  ),
                  title: const Text('New Group'),
                  onTap: () => _showCreateGroupDialog(context),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(profile['username'] ?? 'Unknown User'),
                        subtitle: const Text('Online'), // Placeholder for status
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: profile['id'], // Use profile ID as chatId for direct messages
                                isGroupChat: false,
                                receiverId: profile['id'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final TextEditingController groupNameController = TextEditingController();
    List<Map<String, dynamic>> selectedMembers = [];

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Create New Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(hintText: 'Group Name'),
                ),
                const SizedBox(height: 16),
                const Text('Select Members:'),
                // Use a StatefulBuilder to update the dialog's state
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      children: _profiles.map((profile) {
                        final isSelected = selectedMembers.contains(profile);
                        return CheckboxListTile(
                          title: Text(profile['username'] ?? 'Unknown User'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedMembers.add(profile);
                              } else {
                                selectedMembers.remove(profile);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                if (groupNameController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Group name cannot be empty!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                await _createGroup(groupNameController.text, selectedMembers);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGroup(String groupName, List<Map<String, dynamic>> members) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // 1. Create the group
      final newGroup = await supabase.from('groups').insert({
        'name': groupName,
        'created_by': currentUserId,
      }).select().single();

      final groupId = newGroup['id'];

      // 2. Add creator as a member and admin
      List<Map<String, dynamic>> groupMembersToInsert = [
        {'group_id': groupId, 'user_id': currentUserId, 'is_admin': true},
      ];

      // 3. Add selected members
      for (var member in members) {
        groupMembersToInsert.add({
          'group_id': groupId,
          'user_id': member['id'],
          'is_admin': false, // New members are not admins by default
        });
      }

      await supabase.from('group_members').insert(groupMembersToInsert);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "$groupName" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the new group chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: groupId,
            isGroupChat: true,
            receiverId: null, // No single receiver for group chat
          ),
        ),
      );
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
