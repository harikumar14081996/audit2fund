import 'package:audit2fund/data/datasources/database_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SettingsService {
  final DatabaseService _databaseService;

  SettingsService(this._databaseService);

  static const String _keyOfficeStartTime = 'office_start_time';
  static const String _keyOfficeEndTime = 'office_end_time';
  static const String _keyWorkingDays = 'working_days'; // Comma separated ints

  // Defaults
  static const TimeOfDay _defaultStartTime = TimeOfDay(hour: 9, minute: 30);
  static const TimeOfDay _defaultEndTime = TimeOfDay(hour: 17, minute: 0);
  static const List<int> _defaultWorkingDays = [1, 2, 3, 4, 5]; // Mon-Fri

  Future<void> _setValue(String key, String value) async {
    final db = await _databaseService.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _getValue(String key) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setOfficeStartTime(TimeOfDay time) async {
    await _setValue(_keyOfficeStartTime, '${time.hour}:${time.minute}');
  }

  Future<TimeOfDay> getOfficeStartTime() async {
    final val = await _getValue(_keyOfficeStartTime);
    if (val == null) return _defaultStartTime;
    final parts = val.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setOfficeEndTime(TimeOfDay time) async {
    await _setValue(_keyOfficeEndTime, '${time.hour}:${time.minute}');
  }

  Future<TimeOfDay> getOfficeEndTime() async {
    final val = await _getValue(_keyOfficeEndTime);
    if (val == null) return _defaultEndTime;
    final parts = val.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setWorkingDays(List<int> days) async {
    await _setValue(_keyWorkingDays, days.join(','));
  }

  Future<List<int>> getWorkingDays() async {
    final val = await _getValue(_keyWorkingDays);
    if (val == null) return _defaultWorkingDays;
    if (val.isEmpty) return [];
    return val.split(',').map((e) => int.parse(e)).toList();
  }
}
