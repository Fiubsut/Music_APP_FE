import 'package:flutter/material.dart';
import 'package:flutter_application_1/music_player_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({Key? key, required this.playlistId}) : super(key: key);

  @override
  _PlaylistDetailPageState createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  Map<String, dynamic>? playlistDetails;
  List<Map<String, dynamic>> tracks = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylistDetails();
  }

  // Fetch playlist details
  Future<void> fetchPlaylistDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists/${widget.playlistId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract trackIDs from the playlist
        List<dynamic> trackIds = data['trackIDs'];
        
        // Fetch details for each track using trackID
        List<Map<String, dynamic>> trackDetails = [];
        for (var track in trackIds) {
          // Lấy _id từ đối tượng track
          String trackId = track['_id'];
          final trackResponse = await http.get(
            Uri.parse('https://music-app-w554.onrender.com/api/tracks/$trackId'),
          );
          if (trackResponse.statusCode == 200) {
            final trackData = jsonDecode(trackResponse.body);
            trackDetails.add(Map<String, dynamic>.from(trackData));
          } else {
            print('Không thể tải chi tiết bài hát với ID: $trackId');
          }
        }

        setState(() {
          playlistDetails = data;
          tracks = trackDetails;
        });
      } else {
        print('Không thể tải chi tiết playlist');
      }
    } catch (e) {
      print('Lỗi khi tải chi tiết playlist: $e');
    }
  }

  Future<void> deleteTrackFromPlaylist(String trackId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists/${widget.playlistId}/$trackId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          tracks.removeWhere((track) => track['_id'] == trackId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Track removed from playlist'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove track'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error removing track'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmDeleteTrack(String trackId) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa bài hát'),
          content: const Text('Bạn chắc chắn muốn xóa bài hát này khỏi playlist?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteTrackFromPlaylist(trackId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
          child: Text(
            playlistDetails?['playlistName'] ?? 'Loading...',
            style: const TextStyle(
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
          color: Colors.greenAccent,
        ),
      ),
      body: playlistDetails == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            'Playlist này chưa có bài hát',
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
  Widget buildTrackItem(Map<String, dynamic> tracks) {
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
            tracks['trackName'] ?? 'Unknown Track',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            tracks['artistID']['artistName'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => confirmDeleteTrack(tracks['_id']),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayPage(trackId: tracks['_id']),
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
