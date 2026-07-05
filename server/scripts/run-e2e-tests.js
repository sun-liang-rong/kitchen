const { spawnSync } = require("child_process");
const {
  assertSupportedNode,
  prepareTestDatabase,
  testEnv,
} = require("./test-env");

assertSupportedNode();

const env = testEnv();
prepareTestDatabase(env);

const jest = spawnSync(
  "jest",
  ["--config", "./test/jest-e2e.json", ...process.argv.slice(2)],
  {
    stdio: "inherit",
    env,
  },
);

process.exit(jest.status ?? 1);
