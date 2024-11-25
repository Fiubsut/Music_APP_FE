// SongListPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'music_player_page.dart';

class SongListPage extends StatelessWidget {
  final List<Map<String, String>> songs = [
    {'title': 'Song 1', 'albumArt': 'assets/song1.jpg'},
    {'title': 'Song 2', 'albumArt': 'assets/song2.jpg'},
    {'title': 'Song 3', 'albumArt': 'assets/song3.jpg'},
    // Add more songs as needed
  ];

  // Fetch the like status of a song from SharedPreferences
  Future<bool> _getLikeStatus(String songTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(songTitle) ?? false; // Return false if no status found
  }

  // Toggle the like status of a song
  Future<void> _toggleLike(String songTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLiked = prefs.getBool(songTitle) ?? false;
    prefs.setBool(songTitle, !isLiked); // Toggle the like status
  }

  // Navigate to the music player screen
  void _navigateToMusicPlayer(BuildContext context, Map<String, String> song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Bài Hát'),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            leading: CircleAvatar(
              backgroundImage: AssetImage(song['albumArt']!),
              radius: 30,
            ),
            title: Text(song['title']!),
            trailing: FutureBuilder<bool>(
              future: _getLikeStatus(song['title']!), // Get like status from SharedPreferences
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Show loading indicator while fetching
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Icon(Icons.favorite_border, color: Colors.grey); // Default to grey if error or no data
                } else {
                  bool isLiked = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: isLiked ? Colors.red : Colors.grey, // Red if liked, grey otherwise
                    ),
                    onPressed: () {
                      _toggleLike(song['title']!); // Toggle like status
                    },
                  );
                }
              },
            ),
            onTap: () => _navigateToMusicPlayer(context, song), // Navigate to music player page on tap
          );
        },
      ),
    );
  }
}
