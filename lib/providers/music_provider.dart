import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/songs_data.dart';

class MusicProvider with ChangeNotifier {
  Song? _currentSong;
  bool _isPlaying = false;
  double _progress = 0.0;
  List<Song> _playlist = SongsData.songs;
  int _currentIndex = 0;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  double get progress => _progress;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  void playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    _progress = 0.0;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void playNext() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _currentSong = _playlist[_currentIndex];
    _isPlaying = true;
    _progress = 0.0;
    notifyListeners();
  }

  void playPrevious() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentSong = _playlist[_currentIndex];
    _isPlaying = true;
    _progress = 0.0;
    notifyListeners();
  }

  void seekTo(double position) {
    _progress = position;
    notifyListeners();
  }
}
