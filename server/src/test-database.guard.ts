export function assertTestDatabase() {
  const databaseUrl = process.env.DATABASE_URL ?? '';
  let databaseName = '';
  try {
    databaseName = new URL(databaseUrl).pathname.replace(/^\//, '');
  } catch {
    // Keep databaseName empty so the guard fails below.
  }

  if (!databaseName.endsWith('_test')) {
    throw new Error(`Refusing to run destructive tests against database: ${databaseName || 'unknown'}`);
  }
}
