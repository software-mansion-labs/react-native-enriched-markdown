import { processColor, type ColorValue } from 'react-native';
import type { MarkdownStyle } from './types/MarkdownStyle';

export const normalizeColor = (
  color: string | undefined
): ColorValue | undefined => (color ? processColor(color) : undefined);

function isSubStyleEqual(
  a: Record<string, unknown>,
  b: Record<string, unknown>
): boolean {
  const keys = Object.keys(a);
  if (keys.length !== Object.keys(b).length) return false;
  for (const key of keys) {
    const valueA = a[key];
    const valueB = b[key];
    if (valueA === valueB) continue;
    if (
      typeof valueA === 'object' &&
      valueA !== null &&
      typeof valueB === 'object' &&
      valueB !== null
    ) {
      const nestedKeysA = Object.keys(valueA);
      const nestedKeysB = Object.keys(valueB);
      if (nestedKeysA.length !== nestedKeysB.length) return false;
      for (const nestedKey of nestedKeysA) {
        if (
          (valueA as Record<string, unknown>)[nestedKey] !==
          (valueB as Record<string, unknown>)[nestedKey]
        ) {
          return false;
        }
      }
      continue;
    }
    return false;
  }
  return true;
}

export function isStyleEqual(
  a: MarkdownStyle,
  b: MarkdownStyle,
  referenceKeys: readonly string[]
): boolean {
  for (const key of referenceKeys) {
    const subA = a[key as keyof MarkdownStyle];
    const subB = b[key as keyof MarkdownStyle];
    if (subA === subB) continue;
    if (!subA || !subB) return false;
    if (
      !isSubStyleEqual(
        subA as Record<string, unknown>,
        subB as Record<string, unknown>
      )
    ) {
      return false;
    }
  }
  return true;
}
