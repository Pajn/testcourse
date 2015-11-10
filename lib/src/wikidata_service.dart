import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Future<Item> getItem(String id) async {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    final response = await _get({'action': 'wbgetentities', 'entity': id, 'format': 'json'});
    final labels = {};
    final descriptions = {};

    final data = (JSON.decode(response.body)['entities'] ?? {})[id];

    if (data != null) {
      data['labels']?.forEach((language, value) {
        labels[language] = value['value'];
      });
      data['descriptions']?.forEach((language, value) {
        descriptions[language] = value['value'];
      });
    }

    return new Item(labels, descriptions);
  }

  Future<Response> _get(Map<String, String> queryParams) =>
      http.get(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());
}

class Item {
  final Map<String, String> label;
  final Map<String, String> description;

  Item(this.label, this.description);
}
