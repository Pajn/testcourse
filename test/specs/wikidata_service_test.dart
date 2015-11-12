import 'dart:convert';
import 'package:guinness2/guinness2.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:wikidata/src/wikidata_service.dart';
import 'package:test/test.dart' show expectAsync;

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

response(Map body, {int statusCode: 200}) async => new Response(JSON.encode(body), statusCode);

main() {
  describe('WikidataService', () {
    describe('#getItem', () {
      Client http;
      WikidataService target;

      beforeEach(() {
        http = new MockClient();
        target = new WikidataService(http);
        when(http.get(any)).thenReturn(response({}));
      });

      it('should throw if the passed id is null', () async {
        target.getItem(null).catchError(expectAsync((e) {
          expect(e).toBeA(ArgumentError);
        }));
      });

      it('should return an item if passed a correct id', () async {
        expect(await target.getItem('Q1')).toBeA(Item);
      });

      it('should throw if passed an invalid id', () {
        target.getItem('P!').catchError(expectAsync((e) {
          expect(e).toBeA(ArgumentError);
        }));
      });

      it('should set the the english label of the item', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q1': {
                  'labels': locals({'en': 'universe'}),
                }
              }
            }));
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'labels': locals({'en': 'Earth'}),
                }
              }
            }));

        final item1 = await target.getItem('Q1');
        final item2 = await target.getItem('Q2');

        expect(item1.label['en']).toEqual('universe');
        expect(item2.label['en']).toEqual('Earth');
      });

      it('should do an API request for the item', () async {
        await target.getItem('Q1');
        await target.getItem('Q2');

        verify(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'})));
        verify(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'})));
      });

      it('should set the english description of the item', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q1': {
                  'descriptions': locals({'en': 'totality of planets, stars, galaxies, intergalactic space, or all matter or all energy'}),
                }
              }
            }));
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'descriptions': locals({'en': 'third planet closest to the Sun in the Solar System'}),
                }
              }
            }));

        final item1 = await target.getItem('Q1');
        final item2 = await target.getItem('Q2');

        expect(item1.description['en']).toEqual('totality of planets, stars, galaxies, intergalactic space, or all matter or all energy');
        expect(item2.description['en']).toEqual('third planet closest to the Sun in the Solar System');
      });

      it('should set the english aliases of the item', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q1': {
                  'aliases': locals({'en': ['cosmos', 'The Universe']}),
                }
              }
            }));
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'aliases': locals({'en': ['Terra', 'the Blue Planet']}),
                }
              }
            }));

        final item1 = await target.getItem('Q1');
        final item2 = await target.getItem('Q2');

        expect(item1.aliases['en']).toEqual(['cosmos', 'The Universe']);
        expect(item2.aliases['en']).toEqual(['Terra', 'the Blue Planet']);
      });

      it('should set the statements of the item', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q1': {
                  'claims': {
                    'P31': [{
                        'mainsnak': {
                            'snaktype': "value",
                            'property': "P31",
                            'datavalue': {
                                'value': {
                                    'entity-type': 'item',
                                    'numeric-id': 1454986
                                },
                                'type': 'wikibase-entityid'
                            },
                            'datatype': 'wikibase-item'
                        },
                        'type': 'statement',
                        'id': r'q1$0479EB23-FC5B-4EEC-9529-CEE21D6C6FA9',
                        'rank': 'normal'
                    }],
                  },
                }
              }
            }));
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'claims': {
                    'P31': [{
                        'mainsnak': {
                            'snaktype': "value",
                            'property': "P31",
                            'datavalue': {
                                'value': {
                                    'entity-type': 'item',
                                    'numeric-id': 3504248
                                },
                                'type': 'wikibase-entityid'
                            },
                            'datatype': 'wikibase-item'
                        },
                        'type': 'statement',
                        'id': r'Q2$50fad68d-4f91-f878-6f29-e655af54690e',
                        'rank': 'normal'
                    }],
                  },
                }
              }
            }));

        final item1 = await target.getItem('Q1');
        final item2 = await target.getItem('Q2');

        expect(item1.statements['P31']).toEqual([new ItemValue(1454986)]);
        expect(item2.statements['P31']).toEqual([new ItemValue(3504248)]);
      });
    });
  });
}
