import 'dart:async';
import 'package:http/http.dart';

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Item getItem(String id) {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    _get({'action': 'wbgetclaims', 'entity': id, 'format': 'json'});
    return new Item({'en': 'universe'});
  }

  Future<Response> _get(Map<String, String> queryParams) =>
      http.get(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());
}

class Item {
  final Map<String, String> label;

  Item(this.label);
}
