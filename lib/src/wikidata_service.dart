import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Item getItem(String id) {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    _get({'action': 'wbgetclaims', 'entity': id, 'format': 'json'});
    final response = _get({'action': 'wbgetentities', 'entity': id, 'format': 'json'});
    final labels = {};

    try {
      final data = JSON.decode(response.body);
      data['entities'][id]['labels'].forEach((language, value) {
        labels[language] = value['value'];
      });
    } on Error {}

    return new Item(labels);
  }

  Response _get(Map<String, String> queryParams) =>
      http.get(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());
}

class Item {
  final Map<String, String> label;

  Item(this.label);
}
