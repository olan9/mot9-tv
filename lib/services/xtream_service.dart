import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class XtreamService {
  final XtreamCredentials creds;
  XtreamService(this.creds);

  String get _base => '${creds.url}/player_api.php?username=${creds.username}&password=${creds.password}';

  Future<bool> login() async {
    try {
      final r = await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return false;
      final j = jsonDecode(r.body);
      return j['user_info'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<Category>> getLiveCategories() async {
    final r = await http.get(Uri.parse('$_base&action=get_live_categories'));
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<LiveChannel>> getLiveStreams({String? categoryId}) async {
    var url = '$_base&action=get_live_streams';
    if (categoryId != null) url += '&category_id=$categoryId';
    final r = await http.get(Uri.parse(url));
    final list = jsonDecode(r.body) as List;
    return list.map((e) => LiveChannel.fromJson(e)).toList();
  }

  Future<List<Category>> getVodCategories() async {
    final r = await http.get(Uri.parse('$_base&action=get_vod_categories'));
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<VodItem>> getVodStreams({String? categoryId}) async {
    var url = '$_base&action=get_vod_streams';
    if (categoryId != null) url += '&category_id=$categoryId';
    final r = await http.get(Uri.parse(url));
    final list = jsonDecode(r.body) as List;
    return list.map((e) => VodItem.fromJson(e)).toList();
  }
}
