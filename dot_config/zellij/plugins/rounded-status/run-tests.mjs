// Run cargo's WASI test executable without a desktop or Zellij server.
import { readFileSync } from 'node:fs';
import { WASI } from 'node:wasi';

if (!process.argv[2]) throw new Error('Usage: node run-tests.mjs <test-executable.wasm>');
const wasi = new WASI({
  version: 'preview1',
  args: ['rounded-status-tests', '--test-threads=1', '--nocapture'],
  env: { RUST_TEST_THREADS: '1' },
  returnOnExit: true,
});
const module = await WebAssembly.compile(readFileSync(process.argv[2]));
const imports = wasi.getImportObject();
for (const item of WebAssembly.Module.imports(module)) {
  if (item.module === 'wasi_snapshot_preview1') continue;
  imports[item.module] ??= {};
  imports[item.module][item.name] = () => {
    throw new Error(`Unexpected real host call during tests: ${item.module}.${item.name}`);
  };
}
const instance = await WebAssembly.instantiate(module, imports);
process.exitCode = wasi.start(instance);
