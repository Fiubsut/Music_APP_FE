import 'package:flutter/material.dart';
import 'package:flutter_application_1/favorite_song_page.dart';
import 'package:flutter_application_1/playlist_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {
      final response = await http.get(
        Uri.parse('https://music-app-w554.onrender.com/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
        });
      }
    }
  }

  Future<void> updateUserInfo(String username, String email, {String? oldPassword, String? newPassword}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {

      if (oldPassword != null && newPassword != null && oldPassword == newPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'New password cannot be the same as the old password.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final payload = {
        'userName': username,
        'email': email,
        if (oldPassword != null) 'oldPassword': oldPassword,
        if (newPassword != null) 'newPassword': newPassword,
      };

      final response = await http.put(
        Uri.parse('https://music-app-w554.onrender.com/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        fetchUserData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Update successful!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (response.statusCode == 400) {
        final errorResponse = jsonDecode(response.body);
        String errorMessage = errorResponse['error'] ?? 'Failed to update user information.';
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An unexpected error occurred.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }


  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Không đăng xuất
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Xác nhận đăng xuất
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Xóa thông tin token và userId khỏi SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Điều hướng người dùng về trang đăng nhập hoặc trang chính
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainPage()),
          (route) => false, // Xóa toàn bộ stack navigation
        );
      }
    }
  }



  void showChangeInfoDialog() {
    final usernameController = TextEditingController(text: userData?['userName'] ?? '');
    final emailController = TextEditingController(text: userData?['email'] ?? '');
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Information', style: TextStyle(color: Colors.greenAccent)),
          backgroundColor: Colors.black87,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await updateUserInfo(
                    usernameController.text,
                    emailController.text,
                    oldPassword: oldPasswordController.text.isNotEmpty ? oldPasswordController.text : null,
                    newPassword: newPasswordController.text.isNotEmpty ? newPasswordController.text : null,
                  );
                  Navigator.of(context).pop(); // Close dialog after successful update
                } catch (error) {
                  print("Failed to update: $error");
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }


  Widget buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.greenAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.grey[800],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: userData == null
            ? const CircularProgressIndicator(color: Colors.greenAccent)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 20),
                    Text(
                      userData!['userName'],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userData!['email'],
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: showChangeInfoDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      ),
                      child: const Text('Change Information', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: Colors.grey[700]),
                    buildMenuItem('Playlist', Icons.queue_music_outlined, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlaylistPage()),
                      );
                    }),
                    buildMenuItem('Favorite Song', Icons.favorite_sharp, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoriteSongsPage()),
                      );
                    }),
                    buildMenuItem('Help & Support', Icons.help_outline, () {}),
                    buildMenuItem('Settings', Icons.settings, () {}),
                    Divider(color: Colors.grey[700]),
                    buildMenuItem('Logout', Icons.logout, logout),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: userData!['profilePicture'] != ''
              ? NetworkImage(userData!['profilePicture'])
              : const AssetImage('assets/avtdf.jpg') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage, // Hàm chọn ảnh
            child: Container(
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(Icons.add, size: 20, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadAvatarToServer(image);
    }
  }  

  Future<void> _uploadAvatarToServer(XFile image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    // Bước 1: Upload ảnh lên Cloudinary
    const String cloudName = 'dvpmjwcmh';
    const String uploadPreset = 'upload_img';
    const String folderName = 'profile_pictures';

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folderName
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        final imageUrl = jsonResponse['secure_url'];
        print(imageUrl);

        final uriUpdate = Uri.parse(
            'https://music-app-w554.onrender.com/api/users/$userId/update_picture');

        final updateResponse = await http.put(
          uriUpdate,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'pictureUrl': imageUrl}),
        );

        if (updateResponse.statusCode == 200) {
          fetchUserData(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Báo lỗi nếu không lưu được trên BE
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update avatar.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Báo lỗi nếu upload lên Cloudinary thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading to Cloudinary: ${response.statusCode}',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error uploading avatar: $e');
    }
  }

}
