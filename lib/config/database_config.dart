class DatabaseConfig {
  // ============================================
  // PostgreSQL Configuration
  // ============================================
  static const String pgHost = 'localhost';
  static const int pgPort = 5432;
  static const String pgDatabase = 'navratri_2026';
  static const String pgUser = 'postgres';
  static const String pgPassword = 'your_password_here';

  // ============================================
  // Connection Mode
  // ============================================
  // true = PostgreSQL (production)
  // false = SQLite (development/testing)
  static bool usePostgreSQL = false;

  // ============================================
  // Environment Based Config
  // ============================================
  static void loadFromEnvironment() {
    // Override with environment variables if available
    // Works with flutter_dotenv or dart define
    usePostgreSQL = const bool.fromEnvironment(
      'USE_POSTGRESQL',
      defaultValue: false,
    );
  }

  // ============================================
  // Production Config (Docker/Cloud)
  // ============================================
  static const String pgHostProduction = 'db-navratri-2026.cxxxxxxx.ap-south-1.rds.amazonaws.com';
  static const String pgDatabaseProduction = 'navratri_2026';
  static const String pgUserProduction = 'admin';
  static const String pgPasswordProduction = 'your_production_password';

  // ============================================
  // Local Development Config
  // ============================================
  static const String pgHostLocal = 'localhost';
  static const int pgPortLocal = 5432;
  static const String pgDatabaseLocal = 'navratri_2026';
  static const String pgUserLocal = 'postgres';
  static const String pgPasswordLocal = 'your_local_password';

  // ============================================
  // Docker Compose Config
  // ============================================
  static const String pgHostDocker = 'db'; // service name in docker-compose
  static const int pgPortDocker = 5432;
  static const String pgDatabaseDocker = 'navratri_2026';
  static const String pgUserDocker = 'navratri_admin';
  static const String pgPasswordDocker = 'navratri_secret_2026';
}
