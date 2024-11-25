import 'package:flutter/material.dart';
import 'package:flutter_application_1/music_player_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;

  const AlbumDetailPage({Key? key, required this.albumId}) : super(key: key);

  @override
  _AlbumDetailPageState createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Map<String, dynamic>? albumDetails;
  List<Map<String, dynamic>> tracks = [];

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
    fetchTracks();
  }

  // Fetch album details
  Future<void> fetchAlbumDetails() async {
    try {
      final response = await http.get(Uri.parse('https://music-app-w554.onrender.com/api/albums/${widget.albumId}'));
      if (response.statusCode == 200) {
        setState(() {
          albumDetails = jsonDecode(response.body);
        });
      } else {
        print('Không thể tải chi tiết album');
      }
    } catch (e) {
      print('Lỗi khi tải chi tiết album: $e');
    }
  }

  // Fetch tracks belonging to the album
  Future<void> fetchTracks() async {
    try {
      final response = await http.get(Uri.parse('https://music-app-w554.onrender.com/api/albums/${widget.albumId}'));
      if (response.statusCode == 200) {
        // Assuming the backend now includes the tracks array in the album details response
        final albumData = jsonDecode(response.body);
        final List<dynamic> albumTracks = albumData['trackIDs'];

        setState(() {
          tracks = albumTracks.map((track) => Map<String, dynamic>.from(track)).toList();
        });
      } else {
        print('Không thể tải danh sách bài hát');
      }
    } catch (e) {
      print('Lỗi khi tải danh sách bài hát: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Album Details",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'BungeeInline',
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
        color: Colors.greenAccent ,
        ),
      ),
      body: albumDetails == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display album information
                  Container(
                    height: MediaQuery.of(context).size.height / 4,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(albumDetails!['coverImage'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            albumDetails!['albumName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            albumDetails!['artistID']['artistName'] ?? 'Unknown Artist',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tracks list title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Danh sách bài hát",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bungee',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tracks list
                  tracks.isEmpty
                      ? const Center(
                          child: Text(
                            'Không thể tải bài hát',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : Column(
                          children: tracks.map((track) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: buildTrackItem(track),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  // Build individual track item
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
            albumDetails?['artistID']['artistName'],
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayPage(trackId: track['_id']),
              ),
            );
          },
        ),

        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: const Divider(
            color: Colors.greenAccent, // Màu sắc của đường kẻ
            thickness: 1, // Độ dày của đường kẻ
            indent: 50, // Khoảng cách từ đầu (trái)
            endIndent: 50, // Khoảng cách từ cuối (phải)
          ),
        ),
      ],
    );
  }

}
