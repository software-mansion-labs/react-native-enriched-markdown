export interface KaTeXInstance {
  renderToString(
    expression: string,
    options?: {
      displayMode?: boolean;
      throwOnError?: boolean;
      output?: 'html' | 'mathml' | 'htmlAndMathml';
    }
  ): string;
}

let cached: Promise<KaTeXInstance | null> | null = null;

/**
 * Lazily loads KaTeX on first call and caches the result for subsequent calls.
 * Resolves to null if katex is not installed (optional peer dependency).
 */
export function loadKaTeX(): Promise<KaTeXInstance | null> {
  if (!cached) {
    cached = import('katex')
      .then((m) => (m.default ?? m) as unknown as KaTeXInstance)
      .catch(() => null);
  }
  return cached;
}
