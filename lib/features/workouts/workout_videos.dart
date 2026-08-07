/// Suggested workout videos — a browsable library of free YouTube follow-along
/// videos, kept SEPARATE from the timer-based cardio circuits. Titles are the
/// real YouTube titles; tapping a card opens the video on YouTube.
class WorkoutVideo {
  const WorkoutVideo({
    required this.title,
    required this.category,
    required this.url,
    this.note,
  });

  final String title;
  final String category;
  final String url;
  final String? note;

  /// Extracts the YouTube video id from youtu.be, /shorts/ or watch?v= links.
  String? get videoId {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    final segs = uri.pathSegments;
    final i = segs.indexOf('shorts');
    if (i != -1 && i + 1 < segs.length) return segs[i + 1];
    if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
    return segs.isNotEmpty ? segs.last : null;
  }

  /// YouTube thumbnail (loads over the network; a fallback shows if offline).
  String? get thumbnailUrl {
    final id = videoId;
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}

/// The curated video library (titles fetched from YouTube). Add more by
/// appending here.
const List<WorkoutVideo> kWorkoutVideos = [
  WorkoutVideo(
    title: '12 Morning Warm-Up Exercises',
    category: 'Warm-up',
    url: 'https://youtu.be/IljsWpib9Fs',
    note: 'Quick daily warm-up routine',
  ),
  WorkoutVideo(
    title: 'Surya Namaskara A — 3D Anatomy',
    category: 'Warm-up',
    url: 'https://youtu.be/JDf6YBWrnfs',
    note: 'Sun Salutation, shown with muscle anatomy',
  ),
  WorkoutVideo(
    title: 'Surya Namaskara A — 3D Anatomy (Short)',
    category: 'Warm-up',
    url: 'https://youtube.com/shorts/JTK_8TcyiWA',
    note: 'Quick Sun Salutation short',
  ),
  WorkoutVideo(
    title: 'HIIT Cardio Full-Body Workout',
    category: 'Cardio',
    url: 'https://youtube.com/shorts/4x5Li0SXpGc',
  ),
  WorkoutVideo(
    title: '20-Minute Tabata Fat-Burning Workout',
    category: 'Cardio',
    url: 'https://youtu.be/xwRa9kjV5RQ',
    note: 'Easy and effective',
  ),
  WorkoutVideo(
    title: '6-Min Stranger Things Full-Body Workout',
    category: 'Full body',
    url: 'https://youtu.be/7EkAuML163U',
    note: 'Fun interactive follow-along',
  ),
  WorkoutVideo(
    title: '5 Exercises Daily for 90 Days (Fat Loss)',
    category: 'Full body',
    url: 'https://youtube.com/shorts/QTs3E-1lXxw',
  ),
  WorkoutVideo(
    title: 'Top 5 Standing Abs Workout',
    category: 'Core',
    url: 'https://youtube.com/shorts/4d5GVzkAl6U',
  ),
  WorkoutVideo(
    title: '30 Squats Every Day',
    category: 'Legs',
    url: 'https://youtube.com/shorts/h2djm-OJhOo',
  ),
  WorkoutVideo(
    title: '30-Minute Deep Meditation Music for Positive Energy',
    category: 'Meditation & Relax',
    url: 'https://youtu.be/YRJ6xoiRcpQ',
    note: 'Relax mind & body · inner peace',
  ),
];

/// Categories in display order (only those that have videos are shown).
const List<String> kVideoCategories = [
  'Warm-up',
  'Cardio',
  'Full body',
  'Core',
  'Legs',
  'Meditation & Relax',
];

List<WorkoutVideo> videosInCategory(String category) =>
    kWorkoutVideos.where((v) => v.category == category).toList();
