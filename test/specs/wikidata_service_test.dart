import 'package:guinness2/guinness2.dart';
import 'package:wikidata/src/wikidata_service.dart';

main() {
  describe('WikidataService', () {
    describe('#getItem', () {
      WikidataService target;

      beforeEach(() {
        target = new WikidataService();
      });

      it('should throw if the passed id is null', () {
        expect(() => target.getItem(null)).toThrowWith(anInstanceOf: ArgumentError);
      });

      it('should return an entitiy if passed a correct id', () {
        expect(target.getItem('Q1')).toBeA(Item);
      });
    });
  });
}
