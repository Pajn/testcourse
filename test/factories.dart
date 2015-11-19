import 'dart:convert';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';

class MockClient extends Mock implements Client {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

url(Map<String, String> queryParams) =>
    new Uri.https('www.wikidata.org', '/w/api.php', queryParams).toString();

locals(Map languages) {
  final locals = {};

  languages.forEach((language, label) {
    if (label is String) {
      locals[language] = {
        'language': language,
        'value': label,
      };
    } else if (label is List) {
      locals[language] = label.map((value) => {
        'language': language,
        'value': value,
      }).toList();
    }
  });

  return locals;
}

itemSnak(String property, int itemId) => {
  'snaktype': 'value',
  'property': property,
  'datavalue': {
      'value': {
          'entity-type': 'item',
          'numeric-id': itemId
      },
      'type': 'wikibase-entityid'
  },
  'datatype': 'wikibase-item'
};

stringSnak(String property, String value) => {
  'snaktype': 'value',
  'property': property,
  'datavalue': {
      'value': value,
      'type': 'string'
  },
  'datatype': 'string'
};

timeSnak(String property, String time, int precision, {
      int timezone: 0, int before: 0, int after: 0,
      String calendarmodel: 'http://www.wikidata.org/entity/Q1985727'}) => {
  'snaktype': 'value',
  'property': property,
  'datavalue': {
      'value': {
          "time": time,
          "timezone": timezone,
          "before": before,
          "after": after,
          "precision": precision,
          "calendarmodel": calendarmodel
      },
      'type': 'time'
  },
  'datatype': 'time'
};

statement(String statementId, mainsnak, {Map qualifiers, Map references}) {
  final statement = {
    'mainsnak': mainsnak,
    'type': 'statement',
    'id': statementId,
    'rank': 'normal',
  };

  if (qualifiers != null) {
    statement['qualifiers'] = {};

    qualifiers.forEach((property, snaks) {
      statement['qualifiers'][property] = snaks;
    });
    statement['qualifiers-order'] = qualifiers.values.toList();
  }

  if (references != null) {
    statement['references'] = [];

    references.forEach((property, snak) {
      statement['references'].add({
        'snaks': {property: [snak]},
        'snaks-order': [property],
      });
    });
  }

  return statement;
}

response(Map body, {int statusCode: 200}) async => new Response(JSON.encode(body), statusCode);
