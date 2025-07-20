import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileNotifier extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  UserProfileNotifier() {
    // Do not call loadUserProfile here directly, it will be called by ProfileScreen
  }

  Future<void> loadUserProfile({String? userId}) async {
    print('UserProfileNotifier: Starting loadUserProfile for userId: $userId...');
    _isLoading = true;
    notifyListeners();
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;

      if (targetUserId == null) {
        _userProfile = null;
        print('UserProfileNotifier: Target user ID is null, profile set to null.');
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select('username, about, avatar_url, phone_number')
          .eq('id', targetUserId)
          .single()
          .maybeSingle();

      _userProfile = response;
      print('UserProfileNotifier: Profile loaded: $_userProfile');
    } catch (e) {
      print('UserProfileNotifier: Error loading user profile: $e');
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('UserProfileNotifier: loadUserProfile finished. isLoading: $_isLoading');
    }
  }

  Future<void> updateProfileField(String fieldName, String value) async {
    print('UserProfileNotifier: Starting updateProfileField for $fieldName with $value...');
    _isLoading = true;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User is not logged in';
      }

      final response = await _supabase.from('profiles').update({
        fieldName: value,
      }).eq('id', user.id).select(); // Add .select() to get response

      if (response.isEmpty) {
        print('UserProfileNotifier: Update operation returned empty response. Possible RLS issue or no row found.');
      } else {
        print('UserProfileNotifier: Update successful for $fieldName. Response: $response');
      }

      // After successful update, reload the profile to reflect changes
      await loadUserProfile(); // Call the public method
    } on PostgrestException catch (e) {
      print('UserProfileNotifier: PostgrestException updating profile field: ${e.message}');
      rethrow; // Re-throw to be caught by UI
    } catch (e) {
      print('UserProfileNotifier: Generic Error updating profile field: $e');
      rethrow; // Re-throw to be caught by UI
    } finally {
      _isLoading = false;
      notifyListeners();
      print('UserProfileNotifier: updateProfileField finished. isLoading: $_isLoading');
    }
  }

  // Method to update avatar URL specifically
  Future<void> updateAvatarUrl(String newUrl) async {
    print('UserProfileNotifier: Starting updateAvatarUrl with $newUrl...');
    _isLoading = true;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User is not logged in';
      }

      final response = await _supabase.from('profiles').update({
        'avatar_url': newUrl,
      }).eq('id', user.id).select(); // Add .select() to get response

      if (response.isEmpty) {
        print('UserProfileNotifier: Avatar update operation returned empty response. Possible RLS issue or no row found.');
      } else {
        print('UserProfileNotifier: Avatar update successful. Response: $response');
      }

      // After successful update, reload the profile to reflect changes
      await loadUserProfile(); // Call the public method
    } on PostgrestException catch (e) {
      print('UserProfileNotifier: PostgrestException updating avatar URL: ${e.message}');
      rethrow; // Re-throw to be caught by UI
    } catch (e) {
      print('UserProfileNotifier: Generic Error updating avatar URL: $e');
      rethrow; // Re-throw to be caught by UI
    } finally {
      _isLoading = false;
      notifyListeners();
      print('UserProfileNotifier: updateAvatarUrl finished. isLoading: $_isLoading');
    }
  }
}
