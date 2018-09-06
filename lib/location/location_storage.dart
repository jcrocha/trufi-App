import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import 'package:trufi_app/trufi_models.dart';
import 'package:trufi_app/location/location_search_favorites.dart';

class LocationStorage {
  final File _file;
  final Lock _fileLock = new Lock();
  final List<TrufiLocation> _locations;

  LocationStorage(this._file, this._locations);

  Future<List<TrufiLocation>> fetchLocations() async {
    var locations = _locations.toList();
    locations.sort(sortByFavorite);
    return locations;
  }

  Future<List<TrufiLocation>> fetchLocationsWithLimit(int limit) async {
    var locations = _locations.sublist(0, min(_locations.length, limit));
    locations.sort(sortByFavorite);
    return locations;
  }

  add(TrufiLocation location) {
    remove(location);
    _locations.insert(0, location);
    _save();
  }

  remove(TrufiLocation location) {
    _locations.remove(location);
    _save();
  }

  bool contains(TrufiLocation location) {
    return _locations.contains(location);
  }

  _save() async {
    await _fileLock.synchronized(() => writeStorage(_file, _locations));
  }
}

Future<String> get _localPath async {
  return (await getApplicationDocumentsDirectory()).path;
}

Future<File> localFile(String fileName) async {
  return File('${await _localPath}/$fileName');
}

Future<File> writeStorage(File file, List<TrufiLocation> locations) {
  return file.writeAsString(
      json.encode(locations.map((location) => location.toJson()).toList()));
}

Future<List<TrufiLocation>> readStorage(File file) async {
  try {
    String encoded = await file.readAsString();
    return compute(_parseStorage, encoded);
  } catch (e) {
    print(e);
    return compute(_parseStorage, "[]");
  }
}

List<TrufiLocation> _parseStorage(String encoded) {
  List<TrufiLocation> locations;
  try {
    final parsed = json.decode(encoded);
    locations = parsed
        .map<TrufiLocation>((json) => new TrufiLocation.fromJson(json))
        .toList();
  } catch (e) {
    print(e);
    locations = List();
  }
  return locations;
}