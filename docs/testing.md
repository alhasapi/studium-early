# Testing

On Linux/macOS, run from the repository root:

```sh
./tests/run.sh
```

This runs unit and integration tests for arithmetic, English, and logic, followed by Lua syntax checks. For a real Luanti startup smoke test, run:

```sh
./tests/live_smoke.sh
```

The smoke test creates a temporary SQLite world, loads the installed Studium mods, and fails on startup/runtime errors. Windows developers can run the individual `tests\run.sh` scripts under a Lua/Luanti test environment.
