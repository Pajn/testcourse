import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

bool _multiMapEquals(Map a, Map b) {
  if ((a == null) != (b == null)) return false;
  if (a.length != b.length) return false;

  for (var key in a.keys) {
    if (!listsEqual(a[key], b[key])) return false;
  }

  return true;
}

class Item {
  final String id;
  final Map<String, String> label;
  final Map<String, String> description;
  final Map<String, List<String>> aliases;
  final Map<String, List<Statement>> statements;

  Item(this.id, this.label, this.description, this.aliases, this.statements);

  @override
  operator ==(other) => other is Item &&
    mapsEqual(other.label, label) && mapsEqual(other.description, description) &&
    _multiMapEquals(other.aliases, aliases) &&
    _multiMapEquals(other.statements, statements);

  @override
  get hashCode => hashObjects([label, description, aliases, statements]);

  @override
  toString() => 'Item($label, description: $description, aliases: $aliases, statements: $statements)';
}

class Statement {
  final Value value;
  final String id;
  final String property;

  final Map<String, List<Value>> qualifiers;
  final Map<String, List<Value>> references;

  Statement(this.value, {this.id, this.property,
      Map<String, List<Value>> qualifiers, Map<String, List<Value>> references
    }) : this.qualifiers = qualifiers ?? {}, this.references = references ?? {};

  @override
  operator ==(other) => other is Statement && other.value == value &&
    other.id == id && other.property == property &&
    _multiMapEquals(other.qualifiers, qualifiers) &&
    _multiMapEquals(other.references, references);

  @override
  get hashCode => hashObjects([value, qualifiers, references]);

  @override
  toString() => 'Statement($value, id: $id, property: $property, '
                          'qualifiers: $qualifiers, references: $references)';
}

abstract class Value {}

class ItemValue extends Value {
  final int id;

  ItemValue(this.id);

  @override
  operator ==(other) => other is ItemValue && other.id == id;

  @override
  get hashCode => id.hashCode;

  @override
  toString() => 'ItemValue(Q$id)';
}

class StringValue extends Value {
  final String value;

  StringValue(this.value);

  @override
  operator ==(other) => other is StringValue && other.value == value;

  @override
  get hashCode => value.hashCode;

  @override
  toString() => 'StringValue($value)';
}

class TimeValue extends Value {
  final String time;
  final int precision;
  final int timezone;
  final int before;
  final int after;
  final String calendarmodel;

  TimeValue(this.time, this.precision, {
      this.timezone: 0, this.before: 0, this.after: 0,
      this.calendarmodel: 'http://www.wikidata.org/entity/Q1985727'});

  @override
  operator ==(other) => other is TimeValue && other.time == time && other.precision == precision &&
      other.timezone == timezone && other.before == before && other.after == after &&
      other.calendarmodel == calendarmodel;

  @override
  get hashCode => hashObjects([time, precision, timezone, before, after, calendarmodel]);

  @override
  toString() => 'TimeValue($time, precision: $precision, timezone: $timezone, before: $before'
                ', after: $after, calendarmodel: $calendarmodel)';
}
