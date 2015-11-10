import 'package:http/http.dart';

class WikidataService {
  final RegExp idPattern = new RegExp(r'Q\d+');
  final Client http;

  WikidataService(this.http);

  Item getItem(String id) {
    if (id == null || !idPattern.hasMatch(id)) throw new ArgumentError();
    return new Item({'en': 'universe'});
  }
}

class Item {
  final Map<String, String> label;

  Item(this.label);
}
