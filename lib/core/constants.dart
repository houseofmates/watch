class AppRoutes {
  static const String home = '/';
  static const String music = '/music';
  static const String images = '/images';
  static const String shows = '/shows';
  static const String movies = '/movies';
  static const String porn = '/porn';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String player = '/player';
  static const String imageViewer = '/image-viewer';
}

class MediaCategory {
  static const String all = 'all';
  static const String music = 'music';
  static const String images = 'images';
  static const String shows = 'shows';
  static const String movies = 'movies';
  static const String porn = 'porn';
  static const List<String> values = [all, music, images, shows, movies, porn];
}

class MediaType {
  static const String audio = 'audio';
  static const String image = 'image';
  static const String video = 'video';
}

const List<String> supportedAudioExts = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.wma', '.alac'];
const List<String> supportedVideoExts = ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv', '.wmv', '.m4v', '.ts'];
const List<String> supportedImageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.heic'];

const List<String> adultKeywords = [
  'xxx', 'porn', 'brazzers', 'realitykings', 'blacked', 'pornhub',
  'onlyfans', 'xvideos', 'hentai', 'adult', 'nsfw',
];
