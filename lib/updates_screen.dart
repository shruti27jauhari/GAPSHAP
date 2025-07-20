import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'user_profile_notifier.dart'; // Import UserProfileNotifier

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _updates = [];
  bool _isLoading = false;
  final TextEditingController _updateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('updates')
          .select('*, profiles!updates_admin_id_fkey(username)')
          .order('created_at', ascending: false);
      setState(() {
        _updates = data;
      });
    } catch (e) {
      print('Error fetching updates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching updates: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUpdate() async {
    if (_updateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update content cannot be empty!')),
      );
      return;
    }

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    try {
      await supabase.from('updates').insert({
        'content': _updateController.text,
        'admin_id': currentUserId,
      });
      _updateController.clear();
      await _fetchUpdates(); // Refresh updates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update added successfully!')),
      );
    } catch (e) {
      print('Error adding update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = Provider.of<UserProfileNotifier>(context);
    final bool isAdmin = userProfileNotifier.userProfile?['is_admin'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Add New Update'),
                      content: TextField(
                        controller: _updateController,
                        decoration: const InputDecoration(hintText: 'Type your update here...'),
                        maxLines: 3,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Add'),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // Close dialog
                            await _addUpdate();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _updates.isEmpty
              ? const Center(child: Text('No updates available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _updates.length,
                  itemBuilder: (context, index) {
                    final update = _updates[index];
                    final adminUsername = (update['profiles'] as Map<String, dynamic>?)?['username'] ?? 'Unknown Admin';
                    final createdAt = DateTime.parse(update['created_at']);
                    final formattedTime = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
                    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                'By $adminUsername on $formattedDate at $formattedTime',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
