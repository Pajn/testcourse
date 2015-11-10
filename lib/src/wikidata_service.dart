class WikidataService {
  Item getItem(String id) {
    if (id == null) throw new ArgumentError();
    return new Item();
  }
}

class Item {}
