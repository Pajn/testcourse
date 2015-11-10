import 'package:guinness2/guinness2.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:wikidata/src/wikidata_service.dart';

class MockClient extends Mock implements Client {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

main() {
  describe('WikidataService', () {
    describe('#getItem', () {
      Client http;
      WikidataService target;

      beforeEach(() {
        http = new MockClient();
        target = new WikidataService(http);
      });

      it('should throw if the passed id is null', () {
        expect(() => target.getItem(null)).toThrowWith(anInstanceOf: ArgumentError);
      });

      it('should return an item if passed a correct id', () {
        expect(target.getItem('Q1')).toBeA(Item);
      });

      it('should throw if passed an invalid id', () {
        expect(() => target.getItem('P1')).toThrowWith(anInstanceOf: ArgumentError);
      });

      it('should set the the english label of the item', () {
        expect(target.getItem('Q1').label['en']).toEqual('universe');
      });

      it('should do an API request for the item', () {
        target.getItem('Q1');

        verify(http.get('https://www.wikidata.org/w/api.php?action=wbgetclaims&entity=Q1&format=json'));
      });
    });
  });
}
