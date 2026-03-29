import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiKey = 'e93e7843ef07890fb75f976ac4c91b5c';
const _base = 'https://api.themoviedb.org/3';
const _imgBase = 'https://image.tmdb.org/t/p';

class TmdbMovie {
  final int id;
  final String title;
  final String? overview;
  final String? backdrop;
  final String? poster;
  final String? logo;
  final String? releaseDate;
  final double rating;
  final int? runtime;
  final List<String> genres;
  final List<TmdbCast> cast;

  TmdbMovie({
    required this.id, required this.title,
    this.overview, this.backdrop, this.poster, this.logo,
    this.releaseDate, this.rating = 0, this.runtime,
    this.genres = const [], this.cast = const [],
  });

  String? get backdropUrl => backdrop != null ? '$_imgBase/w1280$backdrop' : null;
  String? get posterUrl => poster != null ? '$_imgBase/w500$poster' : null;
  String? get logoUrl => logo != null ? '$_imgBase/w300$logo' : null;
  String get year => releaseDate?.length != null && releaseDate!.length >= 4 ? releaseDate!.substring(0, 4) : '';
  String get ratingStr => rating.toStringAsFixed(1);
  String get genreStr => genres.take(2).join(' · ');
  String get runtimeStr => runtime != null ? '${runtime}د' : '';
}

class TmdbSeries {
  final int id;
  final String name;
  final String? overview;
  final String? backdrop;
  final String? poster;
  final String? firstAirDate;
  final double rating;
  final List<String> genres;
  final List<TmdbCast> cast;

  TmdbSeries({
    required this.id, required this.name,
    this.overview, this.backdrop, this.poster,
    this.firstAirDate, this.rating = 0,
    this.genres = const [], this.cast = const [],
  });

  String? get backdropUrl => backdrop != null ? '$_imgBase/w1280$backdrop' : null;
  String? get posterUrl => poster != null ? '$_imgBase/w500$poster' : null;
  String get year => firstAirDate?.length != null && firstAirDate!.length >= 4 ? firstAirDate!.substring(0, 4) : '';
  String get ratingStr => rating.toStringAsFixed(1);
}

class TmdbCast {
  final String name;
  final String? photo;
  final String character;

  TmdbCast({required this.name, this.photo, required this.character});
  String? get photoUrl => photo != null ? '$_imgBase/w185$photo' : null;
}

class TmdbService {
  // Cache to avoid duplicate requests
  static final Map<String, TmdbMovie?> _movieCache = {};
  static final Map<String, TmdbSeries?> _seriesCache = {};

  static Future<TmdbMovie?> searchMovie(String query) async {
    if (_movieCache.containsKey(query)) return _movieCache[query];
    try {
      final r = await http.get(Uri.parse(
        '$_base/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&language=ar',
      )).timeout(const Duration(seconds: 8));
      final j = jsonDecode(r.body);
      final results = j['results'] as List;
      if (results.isEmpty) { _movieCache[query] = null; return null; }
      final id = results.first['id'];
      final movie = await getMovieDetails(id);
      _movieCache[query] = movie;
      return movie;
    } catch (_) { _movieCache[query] = null; return null; }
  }

  static Future<TmdbMovie?> getMovieDetails(int id) async {
    try {
      final r = await http.get(Uri.parse(
        '$_base/movie/$id?api_key=$_apiKey&language=ar&append_to_response=credits,images',
      )).timeout(const Duration(seconds: 8));
      final j = jsonDecode(r.body);

      // Get logo
      String? logoPath;
      final logos = j['images']?['logos'] as List? ?? [];
      if (logos.isNotEmpty) {
        final enLogo = logos.firstWhere((l) => l['iso_639_1'] == 'en', orElse: () => logos.first);
        logoPath = enLogo['file_path'];
      }

      final cast = (j['credits']?['cast'] as List? ?? [])
          .take(10)
          .map((c) => TmdbCast(name: c['name'] ?? '', photo: c['profile_path'], character: c['character'] ?? ''))
          .toList();

      return TmdbMovie(
        id: j['id'],
        title: j['title'] ?? '',
        overview: j['overview'],
        backdrop: j['backdrop_path'],
        poster: j['poster_path'],
        logo: logoPath,
        releaseDate: j['release_date'],
        rating: (j['vote_average'] ?? 0).toDouble(),
        runtime: j['runtime'],
        genres: (j['genres'] as List? ?? []).map((g) => g['name'] as String).toList(),
        cast: cast,
      );
    } catch (_) { return null; }
  }

  static Future<TmdbSeries?> searchSeries(String query) async {
    if (_seriesCache.containsKey(query)) return _seriesCache[query];
    try {
      final r = await http.get(Uri.parse(
        '$_base/search/tv?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&language=ar',
      )).timeout(const Duration(seconds: 8));
      final j = jsonDecode(r.body);
      final results = j['results'] as List;
      if (results.isEmpty) { _seriesCache[query] = null; return null; }
      final id = results.first['id'];
      final series = await getSeriesDetails(id);
      _seriesCache[query] = series;
      return series;
    } catch (_) { _seriesCache[query] = null; return null; }
  }

  static Future<TmdbSeries?> getSeriesDetails(int id) async {
    try {
      final r = await http.get(Uri.parse(
        '$_base/tv/$id?api_key=$_apiKey&language=ar&append_to_response=credits',
      )).timeout(const Duration(seconds: 8));
      final j = jsonDecode(r.body);
      final cast = (j['credits']?['cast'] as List? ?? [])
          .take(10)
          .map((c) => TmdbCast(name: c['name'] ?? '', photo: c['profile_path'], character: c['character'] ?? ''))
          .toList();
      return TmdbSeries(
        id: j['id'], name: j['name'] ?? '',
        overview: j['overview'], backdrop: j['backdrop_path'],
        poster: j['poster_path'], firstAirDate: j['first_air_date'],
        rating: (j['vote_average'] ?? 0).toDouble(),
        genres: (j['genres'] as List? ?? []).map((g) => g['name'] as String).toList(),
        cast: cast,
      );
    } catch (_) { return null; }
  }
}
