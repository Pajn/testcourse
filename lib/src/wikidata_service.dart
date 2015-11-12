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

parseSnak(Map snak, {Map<String, List<Value>> references}) {
  if (snak['datatype'] == 'wikibase-item') {
    return new ItemValue(
      snak['datavalue']['value']['numeric-id'],
      references: references
    );
  } else if (snak['datatype'] == 'string') {
    return new StringValue(
      snak['datavalue']['value'],
      references: references
    );
  }
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
    var statements = {};

    final data = (JSON.decode(response.body)['entities'] ?? {})[id];

    if (data != null) {
      labels = flattenLocals(data['labels']);
      descriptions = flattenLocals(data['descriptions']);
      aliases = flattenLocals(data['aliases']);
      data['claims']?.forEach((property, claims) {
        statements[property] = claims
          .map((claim) {
            final references = {};
            claim['references']?.forEach((reference) {
              reference['snaks']?.forEach((property, reference) {
                references[property] = reference
                  .map(parseSnak)
                  .toList();
              });
            });

            return parseSnak(claim['mainsnak'], references: references);
          })
          .toList();
      });
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
  final Map<String, List<Value>> statements;

  Item(this.label, this.description, this.aliases, this.statements);
}

abstract class Value {
  final Map<String, List<Value>> references;

  Value({this.references});
}

class ItemValue extends Value {
  final int id;

  ItemValue(this.id, {Map<String, List<ItemValue>> references}) : super(references: references);

  @override
  operator ==(other) => other is ItemValue && other.id == id;

  @override
  get hashCode => id.hashCode;

  @override
  toString() => 'ItemValue(Q$id)';
}

class StringValue extends Value {
  final String value;

  StringValue(this.value, {Map<String, List<ItemValue>> references}) : super(references: references);

  @override
  operator ==(other) => other is StringValue && other.value == value;

  @override
  get hashCode => value.hashCode;

  @override
  toString() => 'StringValue(Q$value)';
}
