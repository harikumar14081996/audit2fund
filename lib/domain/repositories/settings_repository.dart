import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<TimeOfDay> getOfficeStartTime();
  Future<void> setOfficeStartTime(TimeOfDay time);

  Future<TimeOfDay> getOfficeEndTime();
  Future<void> setOfficeEndTime(TimeOfDay time);

  Future<List<int>> getWorkingDays();
  Future<void> setWorkingDays(List<int> days);
}
