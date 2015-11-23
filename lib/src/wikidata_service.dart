import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:wikidata/src/entities.dart';

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

encodeValue(Value value) {
  if (value is StringValue) {
    return value.value;
  } else if (value is ItemValue) {
    return {'entity-type': 'item', 'numeric-id': value.id};
  } else if (value is TimeValue) {
    return {
      'time': value.time,
      'timezone': value.timezone,
      'before': value.before,
      'after': value.after,
      'precision': value.precision,
      'calendarmodel': value.calendarmodel,
    };
  }
}

decodeValue(Map snak) {
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

encodeSnak(String property, Value value) {
  var type;
  var datatype;
  if (value is StringValue) {
    type = 'string';
    datatype = 'string';
  } else if (value is ItemValue) {
    type = 'wikibase-entityid';
    datatype = 'wikibase-item';
  }
  return {
    'snaktype': 'value',
    'property': property,
    'datavalue': {
      'value': encodeValue(value),
      'type': type,
    },
    'datatype': datatype,
  };
}

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Future<Statement> addQualifiers(Statement statement, Map<String, List<Value>> qualifiers) async {
    final allQualifiers = new Map.from(statement.qualifiers);
    qualifiers.forEach((property, qualifiers) {
      if (allQualifiers.containsKey(property)) {
        allQualifiers[property] = new List.from(allQualifiers[property])..addAll(qualifiers);
      } else {
        allQualifiers[property] = new List.from(qualifiers);
      }
    });

    statement = new Statement(
      statement.value,
      id: statement.id,
      property: statement.property,
      qualifiers: allQualifiers,
      references: statement.references
    );

    final json = {
      'mainsnak': encodeSnak(statement.property, statement.value),
      'type': 'statement',
      'id': statement.id,
      'rank': 'normal',
    };

    if (statement.qualifiers.isNotEmpty) {
      json['qualifiers'] = {};
      statement.qualifiers.forEach((property, values) {
        json['qualifiers'][property] = values.map((value) => encodeSnak(property, value)).toList();
      });
      json['qualifiers-order'] = json['qualifiers'].keys.toList();
    }

    if (statement.references.isNotEmpty) {
      json['references'] = [];
      statement.references.forEach((property, values) {
        json['references'].add({
          'snaks': {property: values.map((value) => encodeSnak(property, value)).toList()},
          'snaks-order': [property],
        });
      });
    }

    final token = await _getToken();

    await _post({'action': 'wbsetclaim', 'claim': JSON.encode(json), 'token': token});

    return statement;
  }

  Future<Item> addStatement(Item item, String property, Statement statement) async {
    final statements = {property: []};
    item.statements.forEach((property, oldStatements) {
      statements[property] = new List.from(oldStatements);
    });
    statements[property].add(statement);
    final updatedItem = new Item(item.id, item.label, item.description, item.aliases, statements);

    final token = await _getToken();

    await _post({'action': 'wbcreateclaim', 'entity': item.id, 'token': token,
                 'property': property, 'snaktype': 'value',
                 'value': JSON.encode(encodeValue(statement.value))});

    return updatedItem;
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
                .map(decodeValue)
                .toList();
            });
            claim['references']?.forEach((reference) {
              reference['snaks']?.forEach((property, reference) {
                references[property] = reference
                  .map(decodeValue)
                  .toList();
              });
            });

            return new Statement(
              decodeValue(claim['mainsnak']),
              id: claim['id'],
              property: claim['mainsnak']['property'],
              rank: claim['rank'],
              qualifiers: qualifiers,
              references: references
            );
          })
          .toList();
      });
    }

    return new Item(id, labels, descriptions, aliases, statements);
  }

  Future login(String user, String password) async {
    final response = await _post({'action': 'login', 'lgname': user, 'lgpassword': password});
    final token = JSON.decode(response.body)['login']['token'];
    await _post({'action': 'login', 'lgname': user, 'lgpassword': password, 'lgtoken': token});
  }

  Future<Response> _get(Map<String, String> queryParams) =>
      http.get(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());

  Future<String> _getToken() async {
    final response = await _get({'action': 'query', 'meta': 'tokens', 'format': 'json'});
    return JSON.decode(response.body)['query']['tokens']['csrftoken'];
  }

  Future<Response> _post(Map<String, String> queryParams) =>
      http.post(new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString());
}
