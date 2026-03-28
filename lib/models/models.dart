class XtreamCredentials {
  final String url;
  final String username;
  final String password;

  XtreamCredentials({required this.url, required this.username, required this.password});

  Map<String, dynamic> toJson() => {'url': url, 'username': username, 'password': password};
  factory XtreamCredentials.fromJson(Map<String, dynamic> j) =>
      XtreamCredentials(url: j['url'], username: j['username'], password: j['password']);
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['category_id'].toString(), name: j['category_name'] ?? '');
}

class LiveChannel {
  final String id;
  final String name;
  final String? logo;
  final String categoryId;
  final String streamType;

  LiveChannel({required this.id, required this.name, this.logo, required this.categoryId, required this.streamType});

  factory LiveChannel.fromJson(Map<String, dynamic> j) => LiveChannel(
        id: j['stream_id'].toString(),
        name: j['name'] ?? '',
        logo: j['stream_icon'],
        categoryId: j['category_id'].toString(),
        streamType: j['stream_type'] ?? 'live',
      );

  String streamUrl(XtreamCredentials c) =>
      '${c.url}/live/${c.username}/${c.password}/$id.ts';
}

class VodItem {
  final String id;
  final String name;
  final String? poster;
  final String? plot;
  final String? year;
  final String categoryId;
  final double rating;

  VodItem({required this.id, required this.name, this.poster, this.plot, this.year, required this.categoryId, this.rating = 0});

  factory VodItem.fromJson(Map<String, dynamic> j) => VodItem(
        id: j['stream_id'].toString(),
        name: j['name'] ?? '',
        poster: j['stream_icon'],
        plot: j['plot'],
        year: j['year']?.toString(),
        categoryId: j['category_id'].toString(),
        rating: double.tryParse(j['rating']?.toString() ?? '0') ?? 0,
      );

  String streamUrl(XtreamCredentials c) =>
      '${c.url}/movie/${c.username}/${c.password}/$id.mp4';
}
