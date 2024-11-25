import 'package:flutter/material.dart';
import 'package:flutter_application_1/music_player_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lottie/lottie.dart';
import 'package:diacritic/diacritic.dart'; // Thư viện để loại bỏ dấu tiếng Việt

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTracks = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAllTracks();
  }

  Future<void> fetchAllTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://music-app-w554.onrender.com/api/tracks'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allTracks = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      print("Error fetching all tracks: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void searchTracks(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final normalizedQuery = removeDiacritics(query.toLowerCase()); // Loại bỏ dấu và chuyển về chữ thường

    final results = _allTracks.where((track) {
      final trackName = track['trackName']?.toLowerCase() ?? '';
      final normalizedTrackName = removeDiacritics(trackName); // Loại bỏ dấu trong tên bài hát
      return normalizedTrackName.contains(normalizedQuery); // Kiểm tra xem có chứa chuỗi tìm kiếm không
    }).toList();

    setState(() {
      _searchResults = results;
    });
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
            track['artistID']['artistName'] ?? 'Unknown Artist',
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
            color: Colors.greenAccent,
            thickness: 1,
            indent: 50,
            endIndent: 50,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: 
          const Text(
            'Search Tracks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'Bungee',
              fontStyle: FontStyle.italic,
            ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: searchTracks,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tracks...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.greenAccent),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No tracks found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return buildTrackItem(_searchResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
