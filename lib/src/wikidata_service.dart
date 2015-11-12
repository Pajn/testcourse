import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';

Map<String, String> flattenLocals(Map<String, Map<String, String>> locals) {
  final flattenedLocals = {};
  locals?.forEach((language, value) {
    if (value is Map) {
      flattenedLocals[language] = value['value'];
    } else if (value is List) {
      flattenedLocals[language] = value.map((value) => value['value']).toList();
    }
  });
  return flattenedLocals;
}

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Future<Item> getItem(String id) async {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    final response = await _get({'action': 'wbgetentities', 'entity': id, 'format': 'json'});
    var labels;
    var descriptions;
    var aliases;
    var statements;

    final data = (JSON.decode(response.body)['entities'] ?? {})[id];

    if (data != null) {
      labels = flattenLocals(data['labels']);
      descriptions = flattenLocals(data['descriptions']);
      aliases = flattenLocals(data['aliases']);
    }

    return new Item(labels, descriptions, aliases, statements);
  }

  Future<Response> _get(Map<String, String> queryParams) =>
      http.get(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());
}

class Item {
  final Map<String, String> label;
  final Map<String, String> description;
  final Map<String, List<String>> aliases;
  final Map<String, List<ItemValue>> statements;

  Item(this.label, this.description, this.aliases, this.statements);
}

class ItemValue {
  final String id;

  ItemValue(this.id);
}
