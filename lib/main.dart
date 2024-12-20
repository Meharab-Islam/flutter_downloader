import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  runApp(const VideoDownloaderApp());
}

class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Downloader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VideoDownloaderScreen(),
    );
  }
}

class VideoDownloaderScreen extends StatefulWidget {
  const VideoDownloaderScreen({super.key});

  @override
  State<VideoDownloaderScreen> createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  String _status = '';

  /// Handles video downloading with error handling
  Future<void> _downloadVideo(String url) async {
    setState(() {
      _isDownloading = true;
      _status = 'Initializing download...';
    });

    try {
      // Validate URL
      if (!url.startsWith('http')) {
        throw FormatException('Invalid URL format. Make sure it starts with "http".');
      }

      // Initialize YouTube Explode
      var yt = YoutubeExplode();

      setState(() {
        _status = 'Fetching video details...';
      });

      // Parse video URL and get the manifest
      var videoId = VideoId(url);
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.muxed.withHighestBitrate();

      if (streamInfo == null) {
        throw Exception('No downloadable video stream found.');
      }

      setState(() {
        _status = 'Preparing to download...';
      });

      // Get directory
      var appDocDir = await getApplicationDocumentsDirectory();
      var filePath = '${appDocDir.path}/${videoId.value}.mp4';

      // Start the download
      var stream = yt.videos.streamsClient.get(streamInfo);
      var file = File(filePath);
      var fileStream = file.openWrite();

      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      setState(() {
        _status = 'Download Completed: $filePath';
      });

      yt.close();
    } on SocketException {
      setState(() {
        _status = 'Network error: Please check your internet connection.';
      });
    } on FormatException catch (e) {
      setState(() {
        _status = 'Input error: ${e.message}';
      });
    } on FileSystemException {
      setState(() {
        _status = 'File system error: Unable to save the video.';
      });
    } catch (e) {
      setState(() {
        _status = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// Builds the UI of the downloader screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Video URL:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste YouTube, Facebook, or Instagram URL',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDownloading
                  ? null
                  : () async {
                      var url = _urlController.text.trim();
                      if (url.isNotEmpty) {
                        await _downloadVideo(url);
                      } else {
                        setState(() {
                          _status = 'Please enter a valid URL!';
                        });
                      }
                    },
              child: _isDownloading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Download'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontSize: 16, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
