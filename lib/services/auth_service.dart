import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    _token = extractedUserData['token'];
    _user = User.fromJson(extractedUserData['user']);
    notifyListeners();
    return true;
  }

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'password': password,
        },
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token']; 
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
        } else {
             _user = User.fromJson(data);
        }

        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': _token,
          'user': data['user'] ?? data, // Save the raw user data structure
        });
        prefs.setString('userData', userData);

        notifyListeners();
        return null; // Success
      } else {
        print('Login failed: ${response.body}');
        return 'Login failed. Status: ${response.statusCode}';
      }
    } catch (e) {
      print('Login error: $e');
      return 'Connection error: $e';
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    if (_user == null) return 'User not logged in';

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePasswordEndpoint}');
    try {
      final response = await http.post(
        url,
        body: {
          'email': _user!.email,
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
        headers: {
          'Accept': 'application/json',
          if(_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        print('Change password failed: ${response.body}');
        try {
          final data = json.decode(response.body);
          // Check for 'message' or 'error' key
          if (data['message'] != null) {
            return data['message'].toString();
          } else if (data['error'] != null) {
            return data['error'].toString();
          }
        } catch (_) {}
        return 'Failed to change password: ${response.statusCode}';
      }
    } catch (e) {
      print('Change password error: $e');
      return 'An error occurred: $e';
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
  }
}
