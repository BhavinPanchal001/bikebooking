import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/location/data/models/state_model.dart';
import '../../features/location/data/models/city_model.dart';
import '../../features/location/data/models/area_model.dart';

/// Singleton helper for the read-only locations SQLite database.
///
/// On first launch (or version bump), copies the pre-built `locations.db`
/// from assets into the app's documents directory, then opens it.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Bump this whenever you replace assets/db/locations.db with new data.
  static const int _dbVersion = 2;
  static const String _dbName = 'locations.db';
  static const String _versionKey = 'db_version';

  /// Returns the opened database, copying from assets if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    // Check if the DB file exists and if it matches the current version
    final file = File(path);
    final versionFile = File('${path}_v');

    bool needsCopy = !file.existsSync();

    if (!needsCopy && versionFile.existsSync()) {
      final storedVersion = int.tryParse(versionFile.readAsStringSync()) ?? 0;
      if (storedVersion < _dbVersion) {
        needsCopy = true;
      }
    } else if (!needsCopy && !versionFile.existsSync()) {
      // DB exists but no version file — assume old version, re-copy
      needsCopy = true;
    }

    if (needsCopy) {
      // Copy from assets
      final data = await rootBundle.load('assets/db/$_dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await file.writeAsBytes(bytes, flush: true);
      await versionFile.writeAsString('$_dbVersion');
    }

    return await openDatabase(
      path,
      readOnly: true,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------------

  /// Returns all states sorted alphabetically.
  Future<List<StateModel>> getStates() async {
    final db = await database;
    final result = await db.query(
      'states',
      orderBy: 'name ASC',
    );
    return result.map((map) => StateModel.fromMap(map)).toList();
  }

  /// Returns states whose name contains [query] (case-insensitive).
  Future<List<StateModel>> searchStates(String query) async {
    final db = await database;
    final result = await db.query(
      'states',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => StateModel.fromMap(map)).toList();
  }

  // ---------------------------------------------------------------------------
  // Cities
  // ---------------------------------------------------------------------------

  /// Returns all cities for a given [stateId], sorted alphabetically.
  Future<List<CityModel>> getCitiesByState(int stateId) async {
    final db = await database;
    final result = await db.query(
      'cities',
      where: 'state_id = ?',
      whereArgs: [stateId],
      orderBy: 'name ASC',
    );
    return result.map((map) => CityModel.fromMap(map)).toList();
  }

  /// Returns cities for [stateId] whose name contains [query].
  Future<List<CityModel>> searchCities(int stateId, String query) async {
    final db = await database;
    final result = await db.query(
      'cities',
      where: 'state_id = ? AND name LIKE ?',
      whereArgs: [stateId, '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => CityModel.fromMap(map)).toList();
  }

  // ---------------------------------------------------------------------------
  // Areas
  // ---------------------------------------------------------------------------

  /// Returns all areas for a given [cityId], sorted alphabetically.
  Future<List<AreaModel>> getAreasByCity(int cityId) async {
    final db = await database;
    final result = await db.query(
      'areas',
      where: 'city_id = ?',
      whereArgs: [cityId],
      orderBy: 'name ASC',
    );
    return result.map((map) => AreaModel.fromMap(map)).toList();
  }

  /// Returns areas for [cityId] whose name contains [query].
  Future<List<AreaModel>> searchAreas(int cityId, String query) async {
    final db = await database;
    final result = await db.query(
      'areas',
      where: 'city_id = ? AND name LIKE ?',
      whereArgs: [cityId, '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => AreaModel.fromMap(map)).toList();
  }

  /// Diagnostic: Returns all areas where latitude or longitude is null or 0.
  Future<List<AreaModel>> getAreasWithoutCoordinates() async {
    final db = await database;
    final result = await db.query(
      'areas',
      where: 'latitude IS NULL OR longitude IS NULL OR latitude = 0 OR longitude = 0',
      orderBy: 'name ASC',
    );
    return result.map((map) => AreaModel.fromMap(map)).toList();
  }

  /// Diagnostic: Prints all areas without coordinates to console.
  /// Call this from app init to see which areas need lat/lng data.
  static Future<void> printAreasWithoutCoordinates() async {
    try {
      final areas = await instance.getAreasWithoutCoordinates();
      print('=== AREAS WITHOUT LAT/LNG (Total: ${areas.length}) ===');
      for (final area in areas) {
        print('  - ${area.name} (ID: ${area.id}, CityID: ${area.cityId})');
      }
      print('=== END ===');
    } catch (e) {
      print('Error querying areas without coordinates: $e');
    }
  }

  /// Closes the database. Call this during app teardown if needed.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
