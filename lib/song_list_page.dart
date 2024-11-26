import 'package:flutter/material.dart';
import 'package:flutter_application_1/album_detail_page.dart';
import 'package:flutter_application_1/music_player_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';  // Để sử dụng Lottie cho biểu tượng track

class SongListPage extends StatefulWidget {
  @override
  _SongListPageState createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  String selectedCategory = 'song';
  List<dynamic> songList = [];
  List<dynamic> albumList = [];
  List<dynamic> artistList = [];

  @override
  void initState() {
    super.initState();
    _fetchData(selectedCategory);
  }

  // Fetch data based on the selected category
  Future<void> _fetchData(String category) async {
    final baseUrl = 'http://music-app-w554.onrender.com/api/';
    String url = '';

    if (category == 'song') {
      url = '${baseUrl}tracks';
    } else if (category == 'album') {
      url = '${baseUrl}albums';
    } else if (category == 'artist') {
      url = '${baseUrl}artists';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (category == 'song') {
            songList = data;
          } else if (category == 'album') {
            albumList = data;
          } else if (category == 'artist') {
            artistList = data;
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Build the list based on the selected category
  Widget _buildList() {
    List<dynamic> listToDisplay = [];
    if (selectedCategory == 'song') {
      listToDisplay = songList;
    } else if (selectedCategory == 'album') {
      listToDisplay = albumList;
    } else if (selectedCategory == 'artist') {
      listToDisplay = artistList;
    }

    return ListView.builder(
      itemCount: listToDisplay.length,
      itemBuilder: (context, index) {
        final item = listToDisplay[index];
        if (selectedCategory == 'song') {
          return buildTrackItem(item);  // Build song item
        } else if (selectedCategory == 'album') {
          return buildAlbumItem(item);  // Build album item
        } else if (selectedCategory == 'artist') {
          return buildArtistItem(item);  // Build artist item
        } else {
          return Container();
        }
      },
    );
  }

  // Build the track (song) item
  Widget buildTrackItem(Map<String, dynamic> track) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: SizedBox(
            width: 50,
            height: 50,
            child: Lottie.asset(
              'assets/lottie/123.json',  // Lottie animation for track icon
              fit: BoxFit.contain,
            ),
          ),
          title: Text(
            track['trackName'] ?? 'Unknown Track',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track['artistID']['artistName'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MusicPlayPage(trackId: track['_id']),  // Replace with your music player page
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

  // Build the album item
  Widget buildAlbumItem(Map<String, dynamic> album) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(album['coverImage'] ?? 'assets/default.jpg'),  // Fallback image if cover is not available
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        album['albumName'] ?? 'Unknown Album',
        style: const TextStyle(color: Colors.white, fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album['artistID']['artistName'] ?? 'Unknown Artist',
        style: const TextStyle(color: Colors.grey, fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(albumId: album['_id']),  // Replace with album detail page
          ),
        );
      },
    );
  }

  // Build the artist item
  Widget buildArtistItem(Map<String, dynamic> artist) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(
            artist['artistName'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            artist['genre'] ?? 'Unknown Genre',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: const Divider(
            color: Colors.greenAccent,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // Category buttons
  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category.toLowerCase();
          _fetchData(selectedCategory);
        });
      },
      // ignore: sort_child_properties_last
      child: Text(
        category,
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedCategory == category.toLowerCase()
            ? Colors.greenAccent
            : Colors.transparent,
        side: BorderSide(color: Colors.greenAccent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton('Song'),
                  _buildCategoryButton('Album'),
                  _buildCategoryButton('Artist'),
                ],
              ),
            ),
            // Display the list based on selected category
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

}
