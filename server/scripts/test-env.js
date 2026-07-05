const { spawnSync } = require("child_process");

function assertSupportedNode() {
  const minimumNode = { major: 18, minor: 18 };
  const [nodeMajor = 0, nodeMinor = 0] = process.versions.node
    .split(".")
    .map((part) => Number.parseInt(part, 10));

  if (
    nodeMajor < minimumNode.major ||
    (nodeMajor === minimumNode.major && nodeMinor < minimumNode.minor)
  ) {
    console.error(
      [
        `Node.js ${process.versions.node} is too old for this project.`,
        "Please run tests with Node.js 18.18 or newer.",
        "For example: nvm use 22 && pnpm test",
      ].join("\n"),
    );
    process.exit(1);
  }
}

function testEnv() {
  const testDatabaseUrl =
    process.env.TEST_DATABASE_URL ??
    "postgresql://kitchen:kitchen@localhost:5432/kitchen_wish_well_test?schema=public";

  const databaseName = (() => {
    try {
      return new URL(testDatabaseUrl).pathname.replace(/^\//, "");
    } catch {
      return "";
    }
  })();

  if (!databaseName.endsWith("_test")) {
    console.error(
      `Refusing to run tests against non-test database: ${databaseName}`,
    );
    process.exit(1);
  }

  return {
    ...process.env,
    DATABASE_URL: testDatabaseUrl,
    NODE_ENV: "test",
  };
}

function prepareTestDatabase(env) {
  const rootUrl = new URL(env.DATABASE_URL);
  const dbName = rootUrl.pathname.replace(/^\//, "");

  if (!/^[a-zA-Z0-9_]+$/.test(dbName)) {
    console.error(`Unsupported test database name: ${dbName}`);
    process.exit(1);
  }

  const createDb = spawnSync(
    "docker",
    [
      "exec",
      "kitchen-wish-postgres",
      "createdb",
      "-U",
      rootUrl.username || "kitchen",
      dbName,
    ],
    { stdio: "pipe", encoding: "utf8", env },
  );

  if (
    createDb.status !== 0 &&
    !`${createDb.stderr}${createDb.stdout}`.includes("already exists")
  ) {
    process.stderr.write(createDb.stderr);
    process.stdout.write(createDb.stdout);
    process.exit(createDb.status ?? 1);
  }

  const migrate = spawnSync("pnpm", ["prisma", "migrate", "deploy"], {
    stdio: "inherit",
    env,
  });

  if (migrate.status !== 0) {
    process.exit(migrate.status ?? 1);
  }
}

module.exports = {
  assertSupportedNode,
  prepareTestDatabase,
  testEnv,
};
