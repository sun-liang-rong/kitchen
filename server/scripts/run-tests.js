const { spawnSync } = require('child_process');

const testDatabaseUrl =
  process.env.TEST_DATABASE_URL ??
  'postgresql://kitchen:kitchen@localhost:5432/kitchen_wish_well_test?schema=public';

const databaseName = (() => {
  try {
    return new URL(testDatabaseUrl).pathname.replace(/^\//, '');
  } catch {
    return '';
  }
})();

if (!databaseName.endsWith('_test')) {
  console.error(`Refusing to run tests against non-test database: ${databaseName}`);
  process.exit(1);
}

const env = {
  ...process.env,
  DATABASE_URL: testDatabaseUrl,
  NODE_ENV: 'test',
};

const rootUrl = new URL(testDatabaseUrl);
const dbName = rootUrl.pathname.replace(/^\//, '');

if (!/^[a-zA-Z0-9_]+$/.test(dbName)) {
  console.error(`Unsupported test database name: ${dbName}`);
  process.exit(1);
}

const createDb = spawnSync(
  'docker',
  [
    'exec',
    'kitchen-wish-postgres',
    'createdb',
    '-U',
    rootUrl.username || 'kitchen',
    dbName,
  ],
  { stdio: 'pipe', encoding: 'utf8', env },
);

if (
  createDb.status !== 0 &&
  !`${createDb.stderr}${createDb.stdout}`.includes('already exists')
) {
  process.stderr.write(createDb.stderr);
  process.stdout.write(createDb.stdout);
  process.exit(createDb.status ?? 1);
}

const migrate = spawnSync('pnpm', ['prisma', 'migrate', 'deploy'], {
  stdio: 'inherit',
  env,
});

if (migrate.status !== 0) {
  process.exit(migrate.status ?? 1);
}

const jest = spawnSync('jest', process.argv.slice(2), {
  stdio: 'inherit',
  env,
});

process.exit(jest.status ?? 1);
