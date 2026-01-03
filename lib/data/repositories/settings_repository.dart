import 'package:audit2fund/data/datasources/settings_service.dart';
import 'package:audit2fund/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsService _service;

  SettingsRepositoryImpl(this._service);

  @override
  Future<TimeOfDay> getOfficeStartTime() => _service.getOfficeStartTime();

  @override
  Future<void> setOfficeStartTime(TimeOfDay time) =>
      _service.setOfficeStartTime(time);

  @override
  Future<TimeOfDay> getOfficeEndTime() => _service.getOfficeEndTime();

  @override
  Future<void> setOfficeEndTime(TimeOfDay time) =>
      _service.setOfficeEndTime(time);

  @override
  Future<List<int>> getWorkingDays() => _service.getWorkingDays();

  @override
  Future<void> setWorkingDays(List<int> days) => _service.setWorkingDays(days);
}
