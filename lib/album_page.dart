import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_info.dart';
import 'song_list_page.dart';
import 'album_detail_page.dart';

class AlbumPage extends StatefulWidget {
  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Map<String, dynamic>? featuredAlbum;
  List<Map<String, dynamic>> Albums = [];

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

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
          // ignore: avoid_print
          print('Không thể lấy thông tin người dùng');
          return null;
        }
      } catch (e) {
        // ignore: avoid_print
        print('Lỗi khi lấy thông tin người dùng: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> fetchAlbums() async {
    try {
      final response = await http.get(Uri.parse('https://music-app-w554.onrender.com/api/albums'));
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> albums = List<Map<String, dynamic>>.from(jsonDecode(response.body));

        if (albums.isNotEmpty) {
          final randomIndex = (albums.length * DateTime.now().millisecondsSinceEpoch ~/ 1000) % albums.length;
          setState(() {
            featuredAlbum = albums[randomIndex];
            Albums = List.from(albums);
          });
        }
      } else {
        // ignore: avoid_print
        print('Không thể tải album');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi khi tải album: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Center(
          child: Text(
            "ALBUM",
            style: TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontFamily: 'Bungee',
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (featuredAlbum != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlbumDetailPage(albumId: featuredAlbum!['_id'])),
                  );
                },
                child: Container(
                  height: MediaQuery.of(context).size.height / 3,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(featuredAlbum!['coverImage']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                          featuredAlbum!['albumName'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          featuredAlbum!['artistID']['artistName'],
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Danh sách Album",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: "Bungee",
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Albums.length,
              itemBuilder: (context, index) {
                final album = Albums[index];
                return buildAlbumItem(album);
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
              // ignore: avoid_print
              onPressed: () => print("Tìm Kiếm"),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserInfoPage()),
                );
              },
              child: FutureBuilder<String?>(
                future: fetchUserProfilePicture(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/avtdf.jpg'),
                      radius: 20,
                    );
                  } else if (snapshot.hasError || snapshot.data == null) {
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

  Widget buildAlbumItem(Map<String, dynamic> album) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(album['coverImage']),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        album['albumName'],
        style: const TextStyle(color: Colors.white, fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album['artistID']['artistName'],
        style: const TextStyle(color: Colors.grey, fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AlbumDetailPage(albumId: album['_id'])),
        );
      },
    );
  }
}
