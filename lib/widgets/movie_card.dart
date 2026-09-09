import 'package:flutter/material.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(
            0,
            hovering ? -8 : 0,
            0,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C1C1C),
                Color(0xFF2A2A2A),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering
                  ? const Color(0xFFE50914)
                  : const Color(0xFF2A2A2A),
            ),
            boxShadow: hovering
                ? [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.35),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 220 / 330,
                child: Container(
                  color: const Color(0xFF1A1A1A),
                  child: widget.movie.posterUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            size: 50,
                            color: Color(0xFF555555),
                          ),
                        )
                      : Image.asset(
                          widget.movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.movie_outlined,
                                size: 50,
                                color: Color(0xFF555555),
                              ),
                            );
                          },
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 10 : 16,
                    isMobile ? 10 : 14,
                    isMobile ? 10 : 16,
                    isMobile ? 11 : 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16.8,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: isMobile ? 7 : 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.movie.genres.map((genre) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 5 : 6,
                              vertical: isMobile ? 3 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6EFD),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 9.5 : 11,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.only(top: 9),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: isMobile ? 13 : 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatDate(widget.movie.releaseDate),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: isMobile ? 11 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}