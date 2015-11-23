import 'dart:convert';
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
      when(http.get(url({'action': 'query', 'meta': 'tokens', 'format': 'json'}))).
          thenReturn(response({
            'batchcomplete': '',
            'query': {'tokens': {'csrftoken': 'token'}}
          }));
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
        final oldItem = new Item('Q1', {'en': 'test'}, {}, {}, {'P42': [
          new Statement(new StringValue('foo'))
        ]});
        final newItem = await target.addStatement(
          oldItem, 'P42', new Statement(new StringValue('bar'))
        );

        expect(oldItem).toEqual(new Item('Q1', {'en': 'test'}, {}, {}, {
          'P42': [new Statement(new StringValue('foo'))]
        }));
        expect(newItem).toEqual(new Item('Q1', {'en': 'test'}, {}, {}, {
          'P42': [new Statement(new StringValue('foo')), new Statement(new StringValue('bar'))]
        }));
      });

      it('should work if no existing statement of that property exists', () async {
        final oldItem = new Item('Q1', {'en': 'test'}, {}, {}, {});
        final newItem = await target.addStatement(
          oldItem, 'P42', new Statement(new StringValue('bar'))
        );

        expect(newItem).toEqual(new Item('Q1', {'en': 'test'}, {}, {}, {
          'P42': [new Statement(new StringValue('bar'))]
        }));
      });

      it('should POST the data with a CSRF token', () async {
        when(http.get(url({'action': 'query', 'meta': 'tokens', 'format': 'json'}))).
            thenReturn(response({
              'batchcomplete': '',
              'query': {'tokens': {'csrftoken': 'b126104g1n73412hd953521d0b43984e564da8ec+\\'}}
            }));

        final oldItem = new Item('Q1', {'en': 'test'}, {}, {}, {});
        await target.addStatement(oldItem, 'P42', new Statement(new StringValue('bar')));

        verify(http.post(url({'action': 'wbcreateclaim', 'entity': 'Q1',
                              'token': 'b126104g1n73412hd953521d0b43984e564da8ec+\\',
                              'property': 'P42', 'snaktype': 'value', 'value': '"bar"'})));
      });

      it('should support ItemValues', () async {
        final oldItem = new Item('Q1', {'en': 'test'}, {}, {}, {});
        await target.addStatement(oldItem, 'P42', new Statement(new ItemValue(2)));

        verify(http.post(url({'action': 'wbcreateclaim', 'entity': 'Q1', 'token': 'token',
                              'property': 'P42', 'snaktype': 'value',
                              'value': '{"entity-type":"item","numeric-id":2}'})));
      });

      it('should support TimeValues', () async {
        final oldItem = new Item('Q1', {'en': 'test'}, {}, {}, {});
        await target.addStatement(oldItem, 'P42', new Statement(
          new TimeValue('-13798000000-00-00T00:00:00Z', 3)
        ));

        verify(http.post(url({'action': 'wbcreateclaim', 'entity': 'Q1', 'token': 'token',
                              'property': 'P42', 'snaktype': 'value',
                              'value': '{'
                                '"time":"-13798000000-00-00T00:00:00Z",'
                                '"timezone":0,'
                                '"before":0,'
                                '"after":0,'
                                '"precision":3,'
                                '"calendarmodel":"http://www.wikidata.org/entity/Q1985727"'
                              '}'})));
      });
    });

    describe('#login', () {
      it('should support login', () async {
        when(http.post(url({'action': 'login', 'lgname': 'user', 'lgpassword': 'password'}))).
            thenReturn(response({
              'login': {
                'result': 'NeedToken',
                'token': 'dfgdfg8d9gfj9584j9345t34jt348'
              }
            }));

        await target.login('user', 'password');

        verify(http.post(url({'action': 'login', 'lgname': 'user', 'lgpassword': 'password',
                              'lgtoken': 'dfgdfg8d9gfj9584j9345t34jt348'})));
      });
    });

    describe('#addQualifiers', () {
      it('should return a new statement with the qualifers added', () async {
        final oldStatement = new Statement(new StringValue('foo'));
        final newStatement = await target.addQualifiers(
          oldStatement, {
            'P459': [new ItemValue(15605), new ItemValue(76250)],
            'P805': [new ItemValue(500699)],
          }
        );

        expect(oldStatement).toEqual(new Statement(new StringValue('foo')));
        expect(newStatement).toEqual(new Statement(new StringValue('foo'), qualifiers: {
          'P459': [new ItemValue(15605), new ItemValue(76250)],
          'P805': [new ItemValue(500699)],
        }));
      });

      it('should keep old qualifers and references', () async {
        final oldStatement = new Statement(new StringValue('foo'),
          qualifiers: {
            'P405': [new ItemValue(15605)],
            'P805': [new ItemValue(64024)],
          },
          references: {
            'P143': [new ItemValue(36578)],
          });
        final newStatement = await target.addQualifiers(
          oldStatement,
          {
            'P459': [new ItemValue(15605)],
            'P805': [new ItemValue(500699)],
          });

        expect(oldStatement).toEqual(new Statement(new StringValue('foo'),
          qualifiers: {
            'P405': [new ItemValue(15605)],
            'P805': [new ItemValue(64024)],
          },
          references: {
            'P143': [new ItemValue(36578)],
          }));
        expect(newStatement).toEqual(new Statement(new StringValue('foo'),
          qualifiers: {
            'P405': [new ItemValue(15605)],
            'P459': [new ItemValue(15605)],
            'P805': [new ItemValue(64024), new ItemValue(500699)],
          },
          references: {
            'P143': [new ItemValue(36578)],
          }));
      });

      it('should POST the data with a CSRF token', () async {
        when(http.get(url({'action': 'query', 'meta': 'tokens', 'format': 'json'}))).
            thenReturn(response({
              'batchcomplete': '',
              'query': {'tokens': {'csrftoken': 'b126104g1n73412hd953521d0b43984e564da8ec+\\'}}
            }));

        final oldStatement = new Statement(
          new StringValue('foo'),
          id: r'Q2$5627445f-43cb-ed6d-3adb-760e85bd17ee',
          property: 'P1',
          qualifiers: {
            'P405': [new ItemValue(15605)],
            'P805': [new ItemValue(64024)],
          },
          references: {
            'P143': [new ItemValue(36578)],
          });
        await target.addQualifiers(
          oldStatement, {
            'P459': [new ItemValue(15605), new ItemValue(76250)],
            'P805': [new ItemValue(500699)],
          }
        );

        verify(http.post(url({'action': 'wbsetclaim', 'claim': JSON.encode(statement(
                                r'Q2$5627445f-43cb-ed6d-3adb-760e85bd17ee',
                                stringSnak('P1', 'foo'),
                                qualifiers: {
                                  'P405': [itemSnak('P405', 15605)],
                                  'P805': [itemSnak('P805', 64024), itemSnak('P805', 500699)],
                                  'P459': [itemSnak('P459', 15605), itemSnak('P459', 76250)],
                                },
                                references: {
                                  'P143': itemSnak('P143', 36578),
                                }
                              )),
                              'token': 'b126104g1n73412hd953521d0b43984e564da8ec+\\'})));
      });
    });
  });
}
