import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayPage extends StatefulWidget {
  final String trackId; // Nhận vào _id của track từ các trang khác

  const MusicPlayPage({Key? key, required this.trackId}) : super(key: key);

  @override
  _MusicPlayPageState createState() => _MusicPlayPageState();
}

class _MusicPlayPageState extends State<MusicPlayPage> {
  late AudioPlayer _audioPlayer; // Khởi tạo AudioPlayer
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<Map<String, dynamic>> userPlaylists = [];
  String? likeId;
  bool isLiked = false;

  String trackName = "Loading...";
  String trackURL = "";
  String artistName = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer(); // Tạo instance mới khi khởi động
    _initAudioPlayer();
    _fetchTrackData().then((_) {
      if (trackURL.isNotEmpty) {
        _playAudio(); // Tự động phát bài hát
      }
    });
    fetchPlaylists();
    checkIfLiked();
  }

  // Hàm lấy dữ liệu bài hát từ API
  Future<void> _fetchTrackData() async {
    final apiUrl = 'http://music-app-w554.onrender.com/api/tracks/${widget.trackId}'; // API Endpoint
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final trackData = json.decode(response.body);
        setState(() {
          trackName = trackData['trackName'];
          trackURL = trackData['trackURL'];
          artistName = trackData['artistID']['artistName'];
        });
      } else {
        throw Exception('Failed to load track');
      }
    } catch (e) {
      setState(() {
        trackName = "Error loading track";
      });
      debugPrint("Error fetching track data: $e");
    }
  }

  // Cấu hình AudioPlayer
  void _initAudioPlayer() {
    _audioPlayer.onPositionChanged.listen((position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
    });
  }

  void _playAudio() async {
    if (trackURL.isNotEmpty) {
      await _audioPlayer.play(UrlSource(trackURL)); // Phát bài hát từ đầu
    }
  }

  // Phát hoặc tạm dừng nhạc
  void _playPauseAudio() async {
  if (_isPlaying) {
    await _audioPlayer.pause(); // Tạm dừng
  } else {
    await _audioPlayer.resume(); // Phát tiếp từ vị trí đã tạm dừng
  }
}

  // Tua lại 5 giây
  void _rewindAudio() {
    final newPosition = _currentPosition - const Duration(seconds: 5);
    _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // Tua đi 5 giây
  void _fastForwardAudio() {
    final newPosition = _currentPosition + const Duration(seconds: 5);
    _audioPlayer.seek(newPosition > _totalDuration ? _totalDuration : newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.stop(); // Dừng nhạc khi thoát
    _audioPlayer.dispose(); // Giải phóng tài nguyên
    super.dispose();
  }


  Future<void> fetchPlaylists() async {
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
          if (!mounted) return;
          setState(() {
            userPlaylists = playlists
                .where((playlist) => playlist['userID']['_id'] == userId)
                .map((playlist) => {
                      'id': playlist['_id'],
                      'title': playlist['playlistName'],
                    })
                .toList();
          });
        } else {
          print('Failed to fetch playlists');
        }
      } catch (e) {
        print('Error fetching playlists: $e');
      }
    }
  }

  Future<void> addToPlaylist(String playlistId) async {
    try {
      final response = await http.put(
        Uri.parse('https://music-app-w554.onrender.com/api/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trackIDs': [widget.trackId]}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to playlist successfully!')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to add to playlist';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding to playlist')),
      );
      print('Error adding to playlist: $e');
    }
  }

  Future<void> checkIfLiked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    try {
      final response = await http.get(
        Uri.parse('https://music-app-w554.onrender.com/api/likes'),
      );

      if (response.statusCode == 200) {
        List<dynamic> likes = jsonDecode(response.body);
        final like = likes.firstWhere(
          (like) =>
              like['userID']['_id'] == userId &&
              like['trackID']['_id'] == widget.trackId,
          orElse: () => null,
        );

        setState(() {
          isLiked = like != null;
          likeId = like?['_id'];
        });
      } else {
        print('Failed to fetch like status');
      }
    } catch (e) {
      print('Error fetching like status: $e');
    }
  }

  Future<void> likeTrack() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    try {
      final response = await http.post(
        Uri.parse('https://music-app-w554.onrender.com/api/likes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userID': userId,
          'trackID': widget.trackId,
        }),
      );
      checkIfLiked();

      if (response.statusCode == 201) {
        setState(() {
          isLiked = true;
        });
      } else {
        print('Failed to like track');
      }
    } catch (e) {
      print('Error liking track: $e');
    }
  }

  Future<void> unlikeTrack() async {
    if (likeId != null) {
      try {
        final response = await http.delete(
          Uri.parse('https://music-app-w554.onrender.com/api/likes/$likeId'),
        );

        if (response.statusCode == 200) {
          checkIfLiked();
          setState(() {
            isLiked = false;
            likeId = null;
          });
        } else {
          print('Failed to unlike track');
        }
      } catch (e) {
        print('Error unliking track: $e');
      }
    }
  }

  Future<void> _showDownloadConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            "Download Confirmation",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Do you want to choose a location to download this song?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _downloadSong(); // Gọi hàm tải bài hát
    }
  }

  Future<void> _downloadSong() async {
    if (trackURL.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No track URL available for download."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Cho phép người dùng chọn đường dẫn
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        // Người dùng hủy bỏ chọn thư mục
        return;
      }

      // Tên tệp tải về
      final fileName = "${trackName.replaceAll(' ', '_')}.mp3";
      final filePath = "$selectedDirectory/$fileName";

      // Tải file bằng Dio
      final dio = Dio();
      await dio.download(
        trackURL,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint("Download progress: $progress%");
          }
        },
      );

      // Hiển thị thông báo khi tải xong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded to: $filePath"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error downloading file: $e"),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error downloading file: $e");
    }
  }

  Future<Directory?> _getDownloadDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint("Error accessing storage: $e");
      return null;
    }
  }

  Future<void> _shareTrack() async {
    if (trackURL.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No track URL available to share."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await Share.share(
        "🎵 Check out this song: $trackName by $artistName. Listen now: $trackURL",
        subject: "Share Song: $trackName",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sharing track: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showPlaylistModal() {
    if (userPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playlists available to add this track.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a Playlist',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: userPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = userPlaylists[index];
                  return ListTile(
                    title: Text(
                      playlist['title'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      addToPlaylist(playlist['id']);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Song",
              style: TextStyle(
                fontFamily: "Bungee",
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
                fontStyle: FontStyle.italic
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (value) {
              switch (value) {
                case 1:
                  showPlaylistModal();
                  break;
                case 2:
                  if (isLiked) {
                    unlikeTrack();
                  } else {
                    likeTrack();
                  }
                  break;
                case 3:
                  _showDownloadConfirmation();
                  break;
                case 4:
                _shareTrack();
                break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: Colors.green),
                    SizedBox(width: 10),
                    Text("Add to Playlist"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(isLiked ? "Unlike" : "Like"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Download"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 4,
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.purple),
                    SizedBox(width: 10),
                    Text("Share"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Lottie.asset(
              'assets/lottie/playerSong.json',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 5),
            _buildTrackName(context),
            const SizedBox(height: 5),
            Text(
              artistName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Slider(
              value: _currentPosition.inSeconds.toDouble(),
              max: _totalDuration.inSeconds.toDouble(),
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _rewindAudio,
                  icon: const Icon(Icons.replay_5, color: Colors.white, size: 40),
                ),
                IconButton(
                  onPressed: _playPauseAudio,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.greenAccent,
                    size: 70,
                  ),
                ),
                IconButton(
                  onPressed: _fastForwardAudio,
                  icon: const Icon(Icons.forward_5, color: Colors.white, size: 40),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }



  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }


  Widget _buildTrackName(BuildContext context) {

    final double containerWidth = MediaQuery.of(context).size.width - 32;

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: trackName,
        style: const TextStyle(
          fontFamily: "Bungee",
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    bool isOverflowing = textPainter.width > containerWidth;

    return SizedBox(
      height: 30,
      child: isOverflowing
          ? Marquee(
              text: trackName,
              style: const TextStyle(
                fontFamily: "Bungee",
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 50.0,
              velocity: 50.0,
              pauseAfterRound: const Duration(seconds: 1),
              startAfter: const Duration(seconds: 1),
            )
          : Text(
              trackName,
              style: const TextStyle(
                fontFamily: "Bungee",
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
    );
  }
}
