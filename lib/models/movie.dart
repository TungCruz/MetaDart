class Movie {
  final int id;
  final String title;
  final String director;
  final String actors;
  final List<String> genres;
  final DateTime releaseDate;
  final int duration;
  final String language;
  final String rating;
  final String description;
  final String posterUrl;
  final String trailerUrl;

  const Movie({
    required this.id,
    required this.title,
    required this.director,
    required this.actors,
    required this.genres,
    required this.releaseDate,
    required this.duration,
    required this.language,
    required this.rating,
    required this.description,
    required this.posterUrl,
    required this.trailerUrl,
  });

  bool get isComingSoon => releaseDate.isAfter(DateTime.now());
}
