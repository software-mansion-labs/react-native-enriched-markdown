import type { MarkdownStyle } from './types/MarkdownStyle';
import type { MarkdownStyleInternal } from './types/MarkdownStyleInternal';

export function flattenSpoilerStyle(
  userSpoiler: MarkdownStyle['spoiler']
): Partial<MarkdownStyleInternal['spoiler']> | undefined {
  if (!userSpoiler) return undefined;
  const flat: Record<string, unknown> = {};
  if (userSpoiler.color !== undefined) flat.color = userSpoiler.color;
  if (userSpoiler.particles?.density !== undefined)
    flat.particleDensity = userSpoiler.particles.density;
  if (userSpoiler.particles?.speed !== undefined)
    flat.particleSpeed = userSpoiler.particles.speed;
  if (userSpoiler.solid?.borderRadius !== undefined)
    flat.solidBorderRadius = userSpoiler.solid.borderRadius;
  return Object.keys(flat).length > 0
    ? (flat as Partial<MarkdownStyleInternal['spoiler']>)
    : undefined;
}

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
