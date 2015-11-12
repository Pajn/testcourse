import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

bool _multiMapEquals(Map a, Map b) {
  if ((a == null) != (b == null)) return false;
  if (a.length != b.length) return false;

  for (var key in a.keys) {
    if (!listsEqual(a[key], b[key])) return false;
  }

  return true;
}

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

parseSnak(Map snak) {
  if (snak['datatype'] == 'wikibase-item') {
    return new ItemValue(snak['datavalue']['value']['numeric-id']);
  } else if (snak['datatype'] == 'string') {
    return new StringValue(snak['datavalue']['value']);
  } else if (snak['datatype'] == 'time') {
    final value = snak['datavalue']['value'];
    return new TimeValue(
      value['time'],
      value['precision'],
      timezone: value['timezone'],
      before: value['before'],
      after: value['after'],
      calendarmodel: value['calendarmodel']
    );
  }
}

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Future<Item> addStatement(Item item, String property, Statement statement) async {
  }

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
            final qualifiers = {};
            final references = {};

            claim['qualifiers']?.forEach((property, qualifier) {
              qualifiers[property] = qualifier
                .map(parseSnak)
                .toList();
            });
            claim['references']?.forEach((reference) {
              reference['snaks']?.forEach((property, reference) {
                references[property] = reference
                  .map(parseSnak)
                  .toList();
              });
            });

            return new Statement(
              parseSnak(claim['mainsnak']),
              qualifiers: qualifiers,
              references: references
            );
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
  final Map<String, List<Statement>> statements;

  Item(this.label, this.description, this.aliases, this.statements);
}

class Statement {
  final Value value;

  final Map<String, List<Value>> qualifiers;
  final Map<String, List<Value>> references;

  Statement(this.value, {Map<String, List<Value>> qualifiers, Map<String, List<Value>> references})
    : this.qualifiers = qualifiers ?? {}, this.references = references ?? {};

  @override
  operator ==(other) => other is Statement && other.value == value &&
    _multiMapEquals(other.qualifiers, qualifiers) &&
    _multiMapEquals(other.references, references);

  @override
  get hashCode => hashObjects([value, qualifiers, references]);

  @override
  toString() => 'Statement($value, qualifiers: $qualifiers, references: $references)';
}

abstract class Value {}

class ItemValue extends Value {
  final int id;

  ItemValue(this.id);

  @override
  operator ==(other) => other is ItemValue && other.id == id;

  @override
  get hashCode => id.hashCode;

  @override
  toString() => 'ItemValue(Q$id)';
}

class StringValue extends Value {
  final String value;

  StringValue(this.value);

  @override
  operator ==(other) => other is StringValue && other.value == value;

  @override
  get hashCode => value.hashCode;

  @override
  toString() => 'StringValue($value)';
}

class TimeValue extends Value {
  final String time;
  final int precision;
  final int timezone;
  final int before;
  final int after;
  final String calendarmodel;

  TimeValue(this.time, this.precision, {
      this.timezone: 0, this.before: 0, this.after: 0,
      this.calendarmodel: 'http://www.wikidata.org/entity/Q1985727'});

  @override
  operator ==(other) => other is TimeValue && other.time == time && other.precision == precision &&
      other.timezone == timezone && other.before == before && other.after == after &&
      other.calendarmodel == calendarmodel;

  @override
  get hashCode => hashObjects([time, precision, timezone, before, after, calendarmodel]);

  @override
  toString() => 'TimeValue($time, precision: $precision, timezone: $timezone, before: $before'
                ', after: $after, calendarmodel: $calendarmodel)';
}
