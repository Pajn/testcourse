import 'package:guinness2/guinness2.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart' show expectAsync;
import 'package:wikidata/src/entities.dart';
import 'package:wikidata/src/wikidata_service.dart';
import '../factories.dart';

main() {
  describe('WikidataService', () {
    Client http;
    WikidataService target;

    beforeEach(() {
      http = new MockClient();
      target = new WikidataService(http);
      when(http.get(any)).thenReturn(response({}));
    });

    describe('#getItem', () {
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
                    'P31': [statement(
                      r'q1$0479EB23-FC5B-4EEC-9529-CEE21D6C6FA9',
                      itemSnak('p31', 1454986)
                    )],
                  },
                }
              }
            }));
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'claims': {
                    'P31': [statement(
                      r'Q2$50fad68d-4f91-f878-6f29-e655af54690e',
                      itemSnak('p31', 3504248)
                    )],
                  },
                }
              }
            }));

        final item1 = await target.getItem('Q1');
        final item2 = await target.getItem('Q2');

        expect(item1.statements['P31']).toEqual([new Statement(new ItemValue(1454986))]);
        expect(item2.statements['P31']).toEqual([new Statement(new ItemValue(3504248))]);
      });

      it('should set the references of a statement', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q2', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q2': {
                  'claims': {
                    'P227': [statement(
                      r'q2$B43AE569-AB2C-4E4F-BA90-DC56CD6DD24B',
                      stringSnak('P227', '4015139-6'),
                      references: {'P143': itemSnak('P143', 36578)}
                    )],
                  },
                }
              }
            }));

        final item = await target.getItem('Q2');

        expect(item.statements['P227']).toEqual([new Statement(
          new StringValue('4015139-6'),
          references: {'P143': [new ItemValue(36578)]}
        )]);
      });

      it('should set the qualifiers of a statement', () async {
        when(http.get(url({'action': 'wbgetentities', 'entity': 'Q1', 'format': 'json'}))).
            thenReturn(response({
              'entities': {
                'Q1': {
                  'claims': {
                    'P580': [statement(
                      r'Q1$789eef0c-4108-cdda-1a63-505cdd324564',
                      timeSnak('P580', '-13798000000-00-00T00:00:00Z', 3),
                      qualifiers: {
                        'P459': [itemSnak('P459', 15605), itemSnak('P459', 76250)],
                        'P805': [itemSnak('P805', 500699)],
                      }
                    )],
                  },
                }
              }
            }));

        final item = await target.getItem('Q1');


        expect(item.statements['P580']).toEqual([new Statement(
          new TimeValue('-13798000000-00-00T00:00:00Z', 3),
          qualifiers: {
            'P459': [new ItemValue(15605), new ItemValue(76250)],
            'P805': [new ItemValue(500699)],
          }
        )]);
      });
    });

    describe('#addStatement', () {
      it('should return a new Item with the statement added', () async {
        final oldItem = new Item({'en': 'test'}, {}, {}, {'P42': [
          new Statement(new StringValue('foo'))
        ]});
        final newItem = await target.addStatement(
          oldItem, 'P42', new Statement(new StringValue('bar'))
        );

        expect(oldItem).toEqual(new Item({'en': 'test'}, {}, {}, {
          'P42': [new Statement(new StringValue('foo'))]
        }));
        expect(newItem).toEqual(new Item({'en': 'test'}, {}, {}, {
          'P42': [new Statement(new StringValue('foo')), new Statement(new StringValue('bar'))]
        }));
      });
    });
  });
}
