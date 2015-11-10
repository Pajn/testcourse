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

      it('should return an item if passed a correct id', () {
        expect(target.getItem('Q1')).toBeA(Item);
      });

      it('should throw if passed an invalid id', () {
        expect(() => target.getItem('P1')).toThrowWith(anInstanceOf: ArgumentError);
      });

      it('should set the the english label of the item', () {
        expect(target.getItem('Q1').label['en']).toEqual('universe');
      });
    });
  });
}
