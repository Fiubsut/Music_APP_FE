import 'package:flutter/material.dart';
import 'package:flutter_application_1/playlist_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<dynamic>? playlists;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
    fetchUserIdAndPlaylists();
  }

  // Fetch playlists from API
  Future<void> fetchUserIdAndPlaylists() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        currentUserId = userId;
      });

      await fetchPlaylists();
    } catch (e) {
      print('Lỗi khi lấy userId: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch playlists from API and filter by userID
  Future<void> fetchPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists'),
      );

      if (response.statusCode == 200) {
        List<dynamic> allPlaylists = jsonDecode(response.body);
        List<dynamic> filteredPlaylists = allPlaylists.where((playlist) {

          final userIdFromPlaylist = playlist['userID']['_id'];
          return userIdFromPlaylist == currentUserId;
        }).toList();


        setState(() {
          playlists = filteredPlaylists;
          isLoading = false;
        });
      } else {
        print('Failed to fetch playlists: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching playlists: $e');
      setState(() {
        isLoading = false;
      });
    }
  }



  // Fetch user info from SharedPreferences
  Future<Map<String, String>> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    return {'userId': userId ?? ''};
  }

  // Create playlist
  Future<void> createPlaylist(String playlistName) async {
    if (playlistName.isEmpty) return;

    Map<String, String> userInfo = await getUserInfo();
    String userId = userInfo['userId'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playlistName': playlistName, 'userID': userId}),
      );

      if (response.statusCode == 201) {
        final newPlaylist = jsonDecode(response.body);

        // Đảm bảo playlistName không null
        setState(() {
          playlists?.add({
            '_id': newPlaylist['_id'],
            'playlistName': newPlaylist['playlistName'] ?? 'Unnamed Playlist',
            'trackIDs': newPlaylist['trackIDs'] ?? [],
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist created successfully'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create playlist'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print('Error creating playlist: $e');
    }
  }


  // Update playlist name
  Future<void> updatePlaylist(String playlistId, String newName) async {
    try {
      final response = await http.put(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playlistName': newName}),
      );

      if (response.statusCode == 200) {
        final updatedPlaylist = jsonDecode(response.body)['playlist'];

        // Cập nhật danh sách playlists trong state
        setState(() {
          playlists = playlists!.map((playlist) {
            if (playlist['_id'] == playlistId) {
              playlist['playlistName'] = updatedPlaylist['playlistName'];
            }
            return playlist;
          }).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist updated successfully'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update playlist';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating playlist'),
          backgroundColor: Colors.redAccent,
        ),
      );
      print('Error updating playlist: $e');
    }
  }


  // Delete playlist
  Future<void> deletePlaylist(String playlistId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists/$playlistId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          playlists = playlists!.where((playlist) => playlist['_id'] != playlistId).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist deleted successfully'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } else {
        print('Failed to delete playlist');
      }
    } catch (e) {
      print('Error deleting playlist: $e');
    }
  }

  // Show dialog to create a new playlist
  void showCreatePlaylistDialog() {
    final TextEditingController playlistNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: playlistNameController,
            decoration: const InputDecoration(hintText: 'Enter playlist name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                createPlaylist(playlistNameController.text);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for deleting playlist
  void showDeleteConfirmation(String playlistId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: const Text('Are you sure you want to delete this playlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deletePlaylist(playlistId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Your Playlists',
            style: TextStyle(
              color: Colors.white, 
              fontFamily: "Bungee",
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              ),
              
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.greenAccent),
            onPressed: showCreatePlaylistDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : playlists == null || playlists!.isEmpty
              ? const Center(
                  child: Text(
                    'No playlists found',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: playlists!.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists![index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: const Icon(Icons.playlist_play, color: Colors.greenAccent, size: 40),
                        title: Text(
                          playlist['playlistName'] ?? 'Unnamed Playlist',
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        subtitle: Text(
                          'Tracks: ${playlist['trackIDs']?.length ?? 0}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailPage(playlistId: playlist['_id']),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                final TextEditingController nameController = TextEditingController();
                                nameController.text = playlist['playlistName'];
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Update Playlist'),
                                    content: TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(hintText: 'Enter new name'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          updatePlaylist(playlist['_id'], nameController.text);
                                        },
                                        child: const Text('Update'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => showDeleteConfirmation(playlist['_id']),
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
