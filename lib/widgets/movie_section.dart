import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final Function(Movie) onMovieTap;

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFF40612)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            int crossAxisCount;

            if (width >= 1200) {
              crossAxisCount = 5;
            } else if (width >= 900) {
              crossAxisCount = 4;
            } else if (width >= 650) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            const spacing = 32.0;

            final cardWidth =
                (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

            final posterHeight = cardWidth * 330 / 220;
            final cardHeight = posterHeight + 165;

            final aspectRatio = cardWidth / cardHeight;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                final movie = movies[index];

                return MovieCard(movie: movie, onTap: () => onMovieTap(movie));
              },
            );
          },
        ),
      ],
    );
  }
}
