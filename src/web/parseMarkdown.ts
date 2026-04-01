import type { ASTNode } from './types';
import type { Md4cFlags } from '../types/MarkdownStyle';

type ParseFn = (
  markdown: string,
  underline: number,
  latexMath: number
) => string;

// Caching the Promise (not the resolved value) means concurrent callers share
// a single WASM initialization — no duplicate loading.
let parserPromise: Promise<ParseFn> | null = null;

// SINGLE_FILE=1 inlines the WASM binary as base64 inside md4c.js, so no
// network fetch is needed — only a one-time decode + compile on first call.
function initializeParser(): Promise<ParseFn> {
  if (!parserPromise) {
    parserPromise = import('./wasm/md4c')
      .then((module) => module.default())
      .then((wasmModule) =>
        wasmModule.cwrap('parseMarkdown', 'string', [
          'string',
          'number',
          'number',
        ])
      ) as Promise<ParseFn>;
  }
  return parserPromise;
}

export async function parseMarkdown(
  markdown: string,
  { underline = false, latexMath = true }: Md4cFlags = {}
): Promise<ASTNode> {
  const parse = await initializeParser();
  return JSON.parse(parse(markdown, underline ? 1 : 0, latexMath ? 1 : 0));
}
