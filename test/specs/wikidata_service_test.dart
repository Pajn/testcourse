import 'package:guinness2/guinness2.dart';
import 'package:wikidata/src/wikidata_service.dart';

main() {
  describe('WikidataService', () {
    describe('#getEntity', () {
      it('should throw if the passed id is null', () {
        final target = new WikidataService();
        expect(() => target.getEntity(null)).toThrowWith(anInstanceOf: ArgumentError);
      });
    });
  });
}
