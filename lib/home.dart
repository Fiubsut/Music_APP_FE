import 'package:flutter/material.dart';
import 'package:flutter_application_1/playlist_page.dart';
import 'package:flutter_application_1/search_page.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'user_info.dart';
import 'music_player_page.dart';
import 'song_list_page.dart';
import 'album_page.dart';
import 'package:marquee/marquee.dart';
// import 'album_list_page.dart'; // Import trang chi tiết album

class HomePage extends StatefulWidget {


  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String?> profilePictureFuture;

  @override
  void initState() {
    super.initState();
    profilePictureFuture = fetchUserProfilePicture();
  }

  // Fetch thông tin người dùng
  Future<Map<String, String>> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');
    
    return {'token': token ?? '', 'userId': userId ?? ''};
  }

  // Lấy ảnh đại diện của người dùng
  Future<String?> fetchUserProfilePicture() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {
      try {
        final response = await http.get(
          Uri.parse('https://music-app-w554.onrender.com/api/users/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> user = jsonDecode(response.body);
          return user['profilePicture'] ?? '';
        } else {
          print('Không thể lấy thông tin người dùng');
          return null;
        }
      } catch (e) {
        print('Lỗi khi lấy thông tin người dùng: $e');
        return null;
      }
    }
    return null;
  }

  void updateProfilePicture() {
    setState(() {
      profilePictureFuture = fetchUserProfilePicture();
    });
  }

  // Fetch bài hát phổ biến
  Future<List<Map<String, dynamic>>> fetchRandomTracks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://music-app-w554.onrender.com/api/tracks'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          List<dynamic> allTracks = jsonDecode(response.body);
          allTracks.shuffle();
          return allTracks.take(7).map((track) => {
            'id': track['_id'],
            'title': track['trackName'],
            'artist': track['artistID']['artistName'],
          }).toList();
        }
      } catch (e) {
        print('Lỗi khi lấy danh sách bài hát: $e');
      }
    }
    return [];
  }

  // Fetch danh sách album từ backend
  Future<List<Map<String, dynamic>>> fetchAlbums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://music-app-w554.onrender.com/api/albums'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          List<dynamic> allAlbums = jsonDecode(response.body);
          return allAlbums.map((album) => {
            'title': album['albumName'],
            'coverImage': album['coverImage'],  // Đường dẫn ảnh bìa album
            'id': album['_id'],  // ID album để sử dụng cho điều hướng
          }).toList();
        } else {
          print('Không thể tải danh sách album');
          return [];
        }
      } catch (e) {
        print('Lỗi khi tải danh sách album: $e');
        return [];
      }
    }
    return [];
  }

  // fetch danh sách playlist
  Future<List<Map<String, dynamic>>> fetchPlaylists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {
      try {
        final response = await http.get(
          Uri.parse('https://music-app-w554.onrender.com/api/playlists'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          List<dynamic> playlists = jsonDecode(response.body);
          // Lọc playlist dựa trên userId
          return playlists
              .where((playlist) => playlist['userID']['_id'] == userId)
              .map((playlist) => {
                    'id': playlist['_id'],
                    'title': playlist['playlistName'],
                  })
              .toList();
        } else {
          print('Không thể tải danh sách playlist');
          return [];
        }
      } catch (e) {
        print('Lỗi khi tải danh sách playlist: $e');
        return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Center(
              child: Text(
                "CAPP MUSIC",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BungeeInline',
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.greenAccent,
                      offset: Offset(4.0, 4.0),
                      blurRadius: 3.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Phần "Phổ Biến"
            const Text(
              "PHỔ BIẾN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'Bungee',
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Phần Hiển thị Track
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchRandomTracks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null) {
                  return const Text(
                    'Không thể tải bài hát',
                    style: TextStyle(color: Colors.red),
                  );
                } else {
                  return SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: snapshot.data!.map((track) {
                          return buildTrackItem(
                            track['id'],         // Truyền đúng trackId
                            track['title'],
                            track['artist'],
                            context,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 5),

            // Phần "Album"
            const Text(
              "ALBUM",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'Bungee',
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),

            // Hiển thị danh sách album
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAlbums(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null) {
                  return const Text(
                    'Không thể tải album',
                    style: TextStyle(color: Colors.red),
                  );
                } else {
                  return SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: snapshot.data!.map((album) {
                        return buildAlbumItem(album['title'], album['coverImage'], album['id'], context);
                      }).toList(),
                    ),
                  );
                }
              },
            ),
            // Phần "Playlist"
            const SizedBox(height: 10),
            const Text(
              "PLAYLIST",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'Bungee',
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.add, color: Colors.greenAccent, size: 40),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistPage(),
                        ),
                      );
                    },
                  );
                } else {
                  // Nếu có playlist, hiển thị danh sách playlist
                  return SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: snapshot.data!.map((playlist) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0), // Khoảng cách giữa các phần tử
                          child: buildPlaylistItem(playlist['title'], context),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.greenAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoPage(),
                  ),
                ).then((_) {
                  updateProfilePicture();
                });
              },
              child: FutureBuilder<String?>(
                future: profilePictureFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/avtdf.jpg'),
                      radius: 20,
                    );
                  } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/avtdf.jpg'),
                      radius: 20,
                    );
                  } else {
                    return CircleAvatar(
                      backgroundImage: NetworkImage(snapshot.data!),
                      radius: 20,
                    );
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.music_note, color: Colors.greenAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SongListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTrackItem(String trackId, String title, String artist, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayPage(trackId: trackId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Lottie.asset(
              'assets/lottie/disc.json',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 130,
              child: title.length <= 20
                  ? Center(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : SizedBox(
                      height: 20,
                      child: Marquee(
                        text: title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 20.0,
                        velocity: 30.0,
                        startAfter: const Duration(seconds: 2),
                        pauseAfterRound: const Duration(seconds: 1),
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              artist,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Build album item with cover image and title
  Widget buildAlbumItem(String title, String imagePath, String albumId, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumPage(),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlaylistItem(String playlistName, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlaylistPage(),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: AssetImage('assets/playlist.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            color: Colors.black54,
            child: playlistName.length <= 10
                ? Text(
                    playlistName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  )
                : Marquee(
                    text: playlistName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    scrollAxis: Axis.horizontal,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    startAfter: const Duration(seconds: 2),
                    pauseAfterRound: const Duration(seconds: 1),
                  ),
          ),
        ],
      ),
    );
  }
}
