import 'package:flutter/material.dart';
import 'package:flutter_application_1/music_player_page.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteSongsPage extends StatefulWidget {
  const FavoriteSongsPage({Key? key}) : super(key: key);

  @override
  _FavoriteSongsPageState createState() => _FavoriteSongsPageState();
}

class _FavoriteSongsPageState extends State<FavoriteSongsPage> {
  List<Map<String, dynamic>> favoriteSongs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavoriteSongs();
  }

  // Fetch user's favorite songs
  Future<void> fetchFavoriteSongs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch all likes for the user
      final response = await http.get(
        Uri.parse('https://music-app-w554.onrender.com/api/likes'),
      );

      if (response.statusCode == 200) {
        List<dynamic> likes = jsonDecode(response.body);

        // Filter likes for the current user
        List<dynamic> userLikes = likes.where((like) => like['userID']['_id'] == userId).toList();
        
        // Fetch details for each track in userLikes
        List<Map<String, dynamic>> trackDetails = [];
        for (var like in userLikes) {
          String trackId = like['trackID']['_id']; // Extract track ID
          final trackResponse = await http.get(
            Uri.parse('https://music-app-w554.onrender.com/api/tracks/$trackId'),
          );

          if (trackResponse.statusCode == 200) {
            final trackData = jsonDecode(trackResponse.body);
            trackDetails.add({
              'trackId': trackData['_id'],
              'trackName': trackData['trackName'],
              'artistName': trackData['artistID']['artistName'],
            });
          } else {
            print('Không thể tải chi tiết bài hát với ID: $trackId');
          }
        }

        // Update state with fetched track details
        setState(() {
          favoriteSongs = trackDetails;
          isLoading = false;
        });
      } else {
        print('Không thể tải danh sách bài hát yêu thích');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải danh sách bài hát yêu thích: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Songs',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "BungeeInline",
            fontWeight: FontWeight.bold,
            fontSize: 30,
            fontStyle: FontStyle.italic
            ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteSongs.isEmpty
              ? const Center(
                  child: Text(
                    'No favorite songs yet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final track = favoriteSongs[index];
                    return buildTrackItem(track);
                  },
                  padding: const EdgeInsets.all(8.0),
                ),
      backgroundColor: Colors.black,
    );
  }

  Widget buildTrackItem(Map<String, dynamic> track) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: SizedBox(
            width: 50,
            height: 50,
            child: Lottie.asset(
              'assets/lottie/123.json',
              fit: BoxFit.contain,
            ),
          ),
          title: Text(
            track['trackName'] ?? 'Unknown Track',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track['artistName'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayPage(trackId: track['trackId']),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: const Divider(
            color: Colors.greenAccent,
            thickness: 1,
            indent: 50,
            endIndent: 50,
          ),
        ),
      ],
    );
  }

}
