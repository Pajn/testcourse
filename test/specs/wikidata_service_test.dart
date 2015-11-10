import 'package:guinness2/guinness2.dart';
import 'package:wikidata/src/wikidata_service.dart';

main() {
  describe('WikidataService', () {
    describe('#getEntity', () {
      WikidataService target;

      beforeEach(() {
        target = new WikidataService();
      });

      it('should throw if the passed id is null', () {
        expect(() => target.getEntity(null)).toThrowWith(anInstanceOf: ArgumentError);
      });
    });
  });
}
