import 'package:flutter/material.dart';

import '../data/movies.dart';
import '../models/movie.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_navbar.dart';
import '../widgets/hero_banner.dart';
import '../widgets/movie_section.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _nowShowingKey = GlobalKey();
  final GlobalKey _comingSoonKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // CUỘN ĐẾN SECTION
  // ============================================================

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;

    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  // ============================================================
  // MỞ CHI TIẾT PHIM
  // ============================================================

  void _openMovieDetail(
    BuildContext context,
    Movie movie,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: movie,

          // Trang chủ
          onGoHome: () {
            Navigator.pop(context);

            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                if (!mounted) return;

                _scrollToSection(_homeKey);
              },
            );
          },

          // Phim đang chiếu
          onGoNowShowing: () {
            Navigator.pop(context);

            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                if (!mounted) return;

                _scrollToSection(_nowShowingKey);
              },
            );
          },

          // Phim sắp chiếu
          onGoComingSoon: () {
            Navigator.pop(context);

            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                if (!mounted) return;

                _scrollToSection(_comingSoonKey);
              },
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final nowShowing =
        movies.where((movie) => !movie.isComingSoon).toList();

    final comingSoon =
        movies.where((movie) => movie.isComingSoon).toList();

    final heroMovie = movies.firstWhere(
      (movie) => movie.posterUrl.isNotEmpty,
      orElse: () => movies.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      body: Stack(
        children: [
          // ======================================================
          // MAIN SCROLL
          // ======================================================

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Khoảng trống cho navbar fixed
              const SliverToBoxAdapter(
                child: SizedBox(height: 70),
              ),

              SliverToBoxAdapter(
                child: _HomeContent(
                  homeKey: _homeKey,
                  nowShowingKey: _nowShowingKey,
                  comingSoonKey: _comingSoonKey,
                  heroMovie: heroMovie,
                  nowShowing: nowShowing,
                  comingSoon: comingSoon,
                  onMovieTap: (movie) {
                    _openMovieDetail(
                      context,
                      movie,
                    );
                  },
                ),
              ),
            ],
          ),

          // ======================================================
          // NAVBAR FIXED
          // ======================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppNavbar(
              // Trang chủ
              onHome: () {
                _scrollToSection(_homeKey);
              },

              // Phim đang chiếu
              onNowShowing: () {
                _scrollToSection(_nowShowingKey);
              },

              // Phim sắp chiếu
              onComingSoon: () {
                _scrollToSection(_comingSoonKey);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// HOME CONTENT
// ==================================================================

class _HomeContent extends StatelessWidget {
  final GlobalKey homeKey;
  final GlobalKey nowShowingKey;
  final GlobalKey comingSoonKey;

  final Movie heroMovie;
  final List<Movie> nowShowing;
  final List<Movie> comingSoon;

  final Function(Movie) onMovieTap;

  const _HomeContent({
    required this.homeKey,
    required this.nowShowingKey,
    required this.comingSoonKey,
    required this.heroMovie,
    required this.nowShowing,
    required this.comingSoon,
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

    return Container(
      key: homeKey,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A2E),
          ],
        ),
      ),

      child: Column(
        children: [
          // ======================================================
          // HERO
          // ======================================================

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1320,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 24,
                  24,
                  isMobile ? 14 : 24,
                  0,
                ),
                child: HeroBanner(
                  movie: heroMovie,

                  onBooking: () {
                    onMovieTap(heroMovie);
                  },
                ),
              ),
            ),
          ),

          // ======================================================
          // MOVIE SECTIONS
          // ======================================================

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1320,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 24,
                  isMobile ? 40 : 65,
                  isMobile ? 14 : 24,
                  0,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // PHIM ĐANG CHIẾU
                    // ==================================================

                    Container(
                      key: nowShowingKey,
                      child: MovieSection(
                        title: 'Phim đang chiếu',
                        movies: nowShowing,
                        onMovieTap: onMovieTap,
                      ),
                    ),

                    const SizedBox(height: 75),

                    // ==================================================
                    // PHIM SẮP CHIẾU
                    // ==================================================

                    Container(
                      key: comingSoonKey,
                      child: MovieSection(
                        title: 'Phim sắp chiếu',
                        movies: comingSoon,
                        onMovieTap: onMovieTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // FOOTER
          // ======================================================

          const AppFooter(),
        ],
      ),
    );
  }
}