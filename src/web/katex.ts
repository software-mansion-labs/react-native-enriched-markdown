export interface KaTeXInstance {
  renderToString(
    expression: string,
    options?: {
      displayMode?: boolean;
      throwOnError?: boolean;
      trust?: boolean;
      output?: 'html' | 'mathml' | 'htmlAndMathml';
    }
  ): string;
}

let katexLoadPromise: Promise<KaTeXInstance | null> | null = null;

/**
 * Lazily loads KaTeX on first call and caches the result for subsequent calls.
 * Resolves to null if katex is not installed (optional peer dependency).
 */
export function loadKaTeX(): Promise<KaTeXInstance | null> {
  if (!katexLoadPromise) {
    katexLoadPromise = import('katex')
      .then((module) => {
        const instance = module.default ?? module;
        if (typeof instance?.renderToString !== 'function') return null;
        return instance as KaTeXInstance;
      })
      .catch(() => null);
  }
  return katexLoadPromise;
}
