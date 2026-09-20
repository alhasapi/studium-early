# Testing

On Linux/macOS, run from the repository root:

```sh
./tests/run.sh
```

This runs the pure logic and integration tests for every module — `edu_core`, `edu_arithmetic`, `edu_number_blocks`, `edu_english_blocks`, and `edu_logic_blocks` — followed by Lua syntax checks over all mod sources.

For a real Luanti startup smoke test, run:

```sh
./tests/live_smoke.sh
```

The smoke test creates a temporary SQLite world, loads **the working tree** into that world's `worldmods` directory, and fails on startup or runtime errors. It runs Luanti with a private home directory so an older copy of a mod installed in your Luanti `mods` folder cannot shadow the checkout, and it injects a marker that proves the checkout is what actually loaded. If Luanti is not installed the test skips; set `STUDIUM_REQUIRE_LUANTI=1` to make a missing Luanti an error instead, which is what CI does.

Both scripts are run by [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) on every push and pull request, along with a live Luanti startup job.

Windows developers can run the individual `tests\run.sh` scripts under a Lua/Luanti test environment.
