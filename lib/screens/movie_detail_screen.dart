import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/movie.dart';
import '../widgets/app_shell.dart';
import 'seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  final VoidCallback? onGoHome;
  final VoidCallback? onGoNowShowing;
  final VoidCallback? onGoComingSoon;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.onGoHome,
    this.onGoNowShowing,
    this.onGoComingSoon,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  YoutubePlayerController? _youtubeController;

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // YOUTUBE VIDEO ID
  // ============================================================

  String? _getYoutubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }

      if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
      }
    } catch (_) {}

    return null;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final videoId = _getYoutubeVideoId(
      widget.movie.trailerUrl,
    );

    if (videoId != null && videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onHome: widget.onGoHome,
      onNowShowing: widget.onGoNowShowing,
      onComingSoon: widget.onGoComingSoon,
      child: _buildPageContent(context),
    );
  }

  // ============================================================
  // PAGE CONTENT
  // ============================================================

  Widget _buildPageContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            24,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackdrop(),

              const SizedBox(height: 32),

              _buildMovieDetails(),

              const SizedBox(height: 48),

              _buildShowtimes(),

              const SizedBox(height: 32),

              if (widget.movie.trailerUrl.isNotEmpty)
                _buildTrailer(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BACKDROP
  // ============================================================

  Widget _buildBackdrop() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  color: const Color(0xFF1A1A1A),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_outlined,
                    size: 80,
                    color: Colors.white24,
                  ),
                );
              },
            ),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.5),
                    Color.fromRGBO(0, 0, 0, 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOVIE DETAILS
  // ============================================================

  Widget _buildMovieDetails() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPoster(),

              const SizedBox(width: 24),

              Expanded(
                child: _buildMovieInformation(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _buildPoster(),
            ),

            const SizedBox(height: 24),

            _buildMovieInformation(),
          ],
        );
      },
    );
  }

  // ============================================================
  // POSTER
  // ============================================================

  Widget _buildPoster() {
    return SizedBox(
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Image.asset(
            widget.movie.posterUrl,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: const Color(0xFF1A1A1A),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.movie_outlined,
                  size: 64,
                  color: Colors.white38,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOVIE INFORMATION
  // ============================================================

  Widget _buildMovieInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.movie.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 24),

        _buildInfoRow(
          'Đạo diễn',
          widget.movie.director,
        ),

        _buildInfoRow(
          'Diễn viên chính',
          widget.movie.actors,
        ),

        _buildInfoRow(
          'Thể loại',
          widget.movie.genres.join(', '),
        ),

        _buildInfoRow(
          'Khởi chiếu',
          _formatDate(widget.movie.releaseDate),
        ),

        _buildInfoRow(
          'Thời lượng',
          '${widget.movie.duration} phút',
        ),

        _buildInfoRow(
          'Ngôn ngữ',
          widget.movie.language,
        ),

        _buildInfoRow(
          'Rated',
          widget.movie.rating,
        ),

        const SizedBox(height: 14),

        Text(
          widget.movie.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHOWTIMES
  // ============================================================

  Widget _buildShowtimes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lịch chiếu'),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn ngày:',
                    style: TextStyle(
                      color: Color(0xFFDDDDDD),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildDateDropdown(
                    width: constraints.maxWidth,
                  ),
                ],
              );
            }

            return Row(
              children: [
                const Text(
                  'Chọn ngày:',
                  style: TextStyle(
                    color: Color(0xFFDDDDDD),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 10),

                _buildDateDropdown(
                  width: 220,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '09:00',
            '11:30',
            '14:00',
            '16:30',
            '19:00',
            '21:30',
          ].map(
            (time) => _buildShowtimeButton(time),
          ).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // DATE DROPDOWN
  // ============================================================

  Widget _buildDateDropdown({
    required double width,
  }) {
    final date = _formatDate(
      widget.movie.releaseDate,
    );

    return Container(
      width: width,
      height: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF444444),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: date,
          isExpanded: true,
          dropdownColor: const Color(0xFF252525),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white70,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          items: [
            DropdownMenuItem(
              value: date,
              child: Text(date),
            ),
          ],
          onChanged: (_) {},
        ),
      ),
    );
  }

  // ============================================================
  // SHOWTIME BUTTON
  // ============================================================

  Widget _buildShowtimeButton(String time) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeatSelectionScreen(
              showtimeId: 122,
              ticketPrice: 100000,
              onGoHome: widget.onGoHome,
              onGoNowShowing: widget.onGoNowShowing,
              onGoComingSoon: widget.onGoComingSoon,
            ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 90,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            time,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TRAILER
  // ============================================================

  Widget _buildTrailer() {
    final controller = _youtubeController;

    if (controller == null) {
      return const Text(
        'Không thể tải trailer.',
        style: TextStyle(
          color: Colors.white70,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Trailer'),

        const SizedBox(height: 18),

        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE50914),
                Color(0xFFF40612),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}