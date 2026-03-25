class AppConstants {
  AppConstants._();

  // Firebase Remote Config keys
  static const String monetizationActiveKey = 'MONETIZATION_ACTIVE';

  // Database
  static const String dbName = 'tazakar.db';
  static const int dbVersion = 2;

  // Free tier limits
  static const int freeTierReminderCap = 10;
  static const int freeTierMaxRecurring = 2;
  static const int freeTierMaxRecurrenceDays = 30;

  // Snooze
  static const int defaultSnoozeDurationMinutes = 10;
}
