"use strict";

// Caching the Promise (not the resolved value) means concurrent callers share
// a single WASM initialization — no duplicate loading.
let parserPromise = null;

// SINGLE_FILE=1 inlines the WASM binary as base64 inside md4c.js, so no
// network fetch is needed — only a one-time decode + compile on first call.
function initializeParser() {
  if (!parserPromise) {
    parserPromise = import('./wasm/md4c').then(module => module.default()).then(wasmModule => wasmModule.cwrap('parseMarkdown', 'string', ['string', 'number', 'number'])).catch(error => {
      parserPromise = null;
      throw error;
    });
  }
  return parserPromise;
}
function isASTNode(value) {
  return typeof value === 'object' && value !== null && 'type' in value && typeof value.type === 'string';
}
export async function parseMarkdown(markdown, {
  underline = false,
  latexMath = true
} = {}) {
  const parse = await initializeParser();
  const result = JSON.parse(parse(markdown, underline ? 1 : 0, latexMath ? 1 : 0));
  if (!isASTNode(result)) {
    throw new Error('WASM parser returned invalid AST');
  }
  return result;
}
//# sourceMappingURL=parseMarkdown.js.map