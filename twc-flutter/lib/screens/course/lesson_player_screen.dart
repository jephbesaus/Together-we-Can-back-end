import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class LessonPlayerScreen extends StatefulWidget {
  final int courseId;
  final int sectionId;
  final int lessonId;
  final String lessonTitle;
  final String lessonType;
  final String? videoUrl;
  final String? content;
  final List<Map<String, dynamic>>? questions;

  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonType,
    this.videoUrl,
    this.content,
    this.questions,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final ApiService _api = Get.find<ApiService>();

  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  bool _isCompleted = false;

  // Quiz state
  Map<int, int?> _selectedAnswers = {};
  bool _quizSubmitted = false;
  int _quizScore = 0;

  // Navigation
  List<Map<String, dynamic>> _allLessons = [];
  int _currentLessonIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    _initLesson();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    try {
      final response = await _api.get('/courses/${widget.courseId}');
      if (response['success']) {
        final sections = (response['data']['course']['sections'] as List?) ?? [];
        final List<Map<String, dynamic>> lessons = [];
        for (final section in sections) {
          final sectionLessons = (section['lessons'] as List?) ?? [];
          for (final lesson in sectionLessons) {
            lessons.add({
              'id': lesson['id'],
              'section_id': section['id'],
              'title': lesson['title'],
              'type': lesson['type'] ?? lesson['lesson_type'] ?? 'text',
              'video_url': lesson['video_url'],
              'content': lesson['content'],
              'is_completed': lesson['is_completed'] ?? false,
            });
          }
        }
        setState(() {
          _allLessons = lessons;
          _currentLessonIndex = lessons.indexWhere((l) => l['id'] == widget.lessonId);
          if (_currentLessonIndex == -1) _currentLessonIndex = 0;
        });
      }
    } catch (e) {
      print('Error loading course data: $e');
    }
  }

  void _initLesson() {
    if (widget.lessonType == 'video' && widget.videoUrl != null) {
      _initVideo(widget.videoUrl!);
    }
  }

  Future<void> _initVideo(String url) async {
    setState(() => _isVideoInitializing = true);
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _videoController!.addListener(_onVideoProgress);
      setState(() => _isVideoInitializing = false);
    } catch (e) {
      setState(() => _isVideoInitializing = false);
      Get.snackbar('Erreur', 'Impossible de charger la vidéo.');
    }
  }

  void _onVideoProgress() {
    if (_videoController == null) return;
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    if (duration.inSeconds > 0 &&
        position.inSeconds >= duration.inSeconds - 2 &&
        !_isCompleted) {
      _completeLesson();
    }
  }

  Future<void> _completeLesson() async {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    try {
      await _api.post('/courses/${widget.courseId}/progress', data: {
        'lesson_id': widget.lessonId,
      });
    } catch (e) {
      print('Error completing lesson: $e');
    }
  }

  void _submitQuiz() {
    int score = 0;
    final questions = widget.questions ?? [];
    for (int i = 0; i < questions.length; i++) {
      final correctIndex = questions[i]['correct_index'] ?? 0;
      if (_selectedAnswers[i] == correctIndex) {
        score++;
      }
    }
    setState(() {
      _quizSubmitted = true;
      _quizScore = score;
    });
    if (score == questions.length) {
      _completeLesson();
    }
  }

  void _navigateToLesson(int offset) {
    final newIndex = _currentLessonIndex + offset;
    if (newIndex < 0 || newIndex >= _allLessons.length) return;
    final lesson = _allLessons[newIndex];
    Get.off(() => LessonPlayerScreen(
          courseId: widget.courseId,
          sectionId: lesson['section_id'],
          lessonId: lesson['id'],
          lessonTitle: lesson['title'],
          lessonType: lesson['type'],
          videoUrl: lesson['video_url'],
          content: lesson['content'],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lessonType == 'video') _buildVideoPlayer(theme),
            if (widget.lessonType == 'text') _buildTextContent(theme),
            if (widget.lessonType == 'quiz') _buildQuiz(theme),
            const SizedBox(height: 24),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _isVideoInitializing
              ? const CircularProgressIndicator()
              : const Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                if (!_videoController!.value.isPlaying)
                  GestureDetector(
                    onTap: () {
                      setState(() => _videoController!.play());
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                    ),
                  ),
                if (_videoController!.value.isPlaying)
                  GestureDetector(
                    onTap: () {
                      setState(() => _videoController!.pause());
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppConstants.primaryColor,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                final pos = _videoController!.value.position - const Duration(seconds: 10);
                _videoController!.seekTo(pos);
              },
              icon: const Icon(Icons.replay_10),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 40,
              ),
            ),
            IconButton(
              onPressed: () {
                final pos = _videoController!.value.position + const Duration(seconds: 10);
                _videoController!.seekTo(pos);
              },
              icon: const Icon(Icons.forward_10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content ?? 'Aucun contenu disponible.',
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isCompleted ? null : _completeLesson,
              icon: Icon(_isCompleted ? Icons.check_circle : Icons.check),
              label: Text(_isCompleted ? 'Terminée' : 'Marquer comme terminée'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCompleted ? Colors.green : AppConstants.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final questions = widget.questions ?? [];

    if (questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aucune question disponible.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quizSubmitted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _quizScore == questions.length
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _quizScore == questions.length ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _quizScore == questions.length ? Icons.emoji_events : Icons.info_outline,
                  color: _quizScore == questions.length ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Score : $_quizScore / ${questions.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _quizScore == questions.length ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(questions.length, (i) {
          final question = questions[i];
          final options = (question['options'] as List?) ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${i + 1}',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question['question'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 12),
                ...List.generate(options.length, (j) {
                  final isSelected = _selectedAnswers[i] == j;
                  final isCorrect = _quizSubmitted && j == (question['correct_index'] ?? 0);
                  final isWrong = _quizSubmitted && isSelected && !isCorrect;

                  Color bgColor = Colors.transparent;
                  if (isCorrect) bgColor = Colors.green.withOpacity(0.1);
                  if (isWrong) bgColor = Colors.red.withOpacity(0.1);
                  if (isSelected && !_quizSubmitted) bgColor = AppConstants.primaryColor.withOpacity(0.1);

                  return GestureDetector(
                    onTap: _quizSubmitted
                        ? null
                        : () => setState(() => _selectedAnswers[i] = j),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                                  ? Colors.red
                                  : isSelected
                                      ? AppConstants.primaryColor
                                      : Colors.grey[300]!,
                          width: isSelected || isCorrect || isWrong ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : isWrong
                                    ? Icons.cancel
                                    : isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                            color: isCorrect
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : isSelected
                                        ? AppConstants.primaryColor
                                        : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[j].toString(),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        if (!_quizSubmitted)
          ElevatedButton(
            onPressed: _selectedAnswers.length == questions.length ? _submitQuiz : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Soumettre les réponses',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigation() {
    final hasPrev = _currentLessonIndex > 0;
    final hasNext = _currentLessonIndex < _allLessons.length - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasPrev ? () => _navigateToLesson(-1) : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Précédent'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasNext ? () => _navigateToLesson(1) : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
