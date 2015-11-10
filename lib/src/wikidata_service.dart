class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');

  Item getItem(String id) {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    return new Item();
  }
}

class Item {}
