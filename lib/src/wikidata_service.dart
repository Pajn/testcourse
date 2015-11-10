class WikidataService {
  Entity getEntity(String id) {
    if (id == null) throw new ArgumentError();
    return new Entity();
  }
}

class Entity {}
