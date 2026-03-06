#pragma once

#include <CoreGraphics/CGBase.h>
#include <React/RCTUtils.h>
#include <list>
#include <mutex>
#include <react/renderer/graphics/Float.h>
#include <string>
#include <tuple>
#include <unordered_map>

namespace facebook::react {

struct HashUtils {

  static inline size_t combine(size_t h, size_t v)
  {
    return h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2));
  }

  template <typename T> static inline void hash_one(size_t &seed, const T &v)
  {
    seed = combine(seed, std::hash<T>{}(v));
  }
};

struct MeasurementCacheKey {
  std::string markdown;
  CGFloat maxWidth;
  bool allowTrailingMargin;
  bool allowFontScaling;
  double maxFontSizeMultiplier;
  bool md4cFlagsUnderline;
  size_t styleFingerprint;
  CGFloat fontScale;

  bool operator==(const MeasurementCacheKey &other) const
  {
    return std::tie(markdown, maxWidth, allowTrailingMargin, allowFontScaling, maxFontSizeMultiplier,
                    md4cFlagsUnderline, styleFingerprint, fontScale) ==
           std::tie(other.markdown, other.maxWidth, other.allowTrailingMargin, other.allowFontScaling,
                    other.maxFontSizeMultiplier, other.md4cFlagsUnderline, other.styleFingerprint, other.fontScale);
  }
};

struct MeasurementCacheKeyHash {
  size_t operator()(const MeasurementCacheKey &key) const
  {
    size_t h = 0;
    HashUtils::hash_one(h, key.markdown);
    HashUtils::hash_one(h, key.maxWidth);
    HashUtils::hash_one(h, key.allowTrailingMargin);
    HashUtils::hash_one(h, key.allowFontScaling);
    HashUtils::hash_one(h, key.maxFontSizeMultiplier);
    HashUtils::hash_one(h, key.md4cFlagsUnderline);
    HashUtils::hash_one(h, key.styleFingerprint);
    HashUtils::hash_one(h, key.fontScale);
    return h;
  }
};

struct CachedSize {
  CGFloat width;
  CGFloat height;
};

template <typename StyleStruct> inline size_t computeStyleFingerprint(const StyleStruct &s)
{
  size_t h = 0;
  auto hashFields = [&](auto... args) { (HashUtils::hash_one(h, args), ...); };

  auto hashTextLayout = [&](const auto &item) {
    hashFields(item.fontFamily, item.fontSize, item.fontWeight, item.marginTop, item.marginBottom, item.lineHeight);
  };

  // Block Elements
  hashTextLayout(s.paragraph);
  hashTextLayout(s.h1);
  hashTextLayout(s.h2);
  hashTextLayout(s.h3);
  hashTextLayout(s.h4);
  hashTextLayout(s.h5);
  hashTextLayout(s.h6);

  hashTextLayout(s.blockquote);
  hashFields(s.blockquote.borderWidth, s.blockquote.gapWidth);

  hashTextLayout(s.list);
  hashFields(s.list.bulletSize, s.list.markerFontWeight, s.list.gapWidth, s.list.marginLeft);

  // Code & Inlines
  hashFields(s.codeBlock.fontFamily, s.codeBlock.fontSize, s.codeBlock.fontWeight, s.codeBlock.marginTop,
             s.codeBlock.marginBottom, s.codeBlock.lineHeight, s.codeBlock.padding, s.codeBlock.borderRadius,
             s.codeBlock.borderWidth);
  hashFields(s.code.fontFamily, s.code.fontSize);
  hashFields(s.link.fontFamily, s.strong.fontFamily, s.strong.fontWeight, s.em.fontFamily, s.em.fontStyle);

  // Visual/Spacing Elements
  hashFields(s.image.height, s.image.marginTop, s.image.marginBottom);
  hashFields(s.inlineImage.size);
  hashFields(s.thematicBreak.height, s.thematicBreak.marginTop, s.thematicBreak.marginBottom);

  // Complex Components
  hashTextLayout(s.table);
  hashFields(s.table.headerFontFamily, s.table.cellPaddingHorizontal, s.table.cellPaddingVertical, s.table.borderWidth,
             s.table.borderRadius);
  hashFields(s.math.fontSize, s.math.padding, s.math.marginTop, s.math.marginBottom);
  hashFields(s.taskList.checkboxSize, s.taskList.checkboxBorderRadius);

  return h;
}

template <typename PropsType>
inline MeasurementCacheKey buildMeasurementCacheKey(const PropsType &props, CGFloat maxWidth, CGFloat fontScale)
{
  return MeasurementCacheKey{
      .markdown = props.markdown,
      .maxWidth = maxWidth,
      .allowTrailingMargin = props.allowTrailingMargin,
      .allowFontScaling = props.allowFontScaling,
      .maxFontSizeMultiplier = props.maxFontSizeMultiplier,
      .md4cFlagsUnderline = props.md4cFlags.underline,
      .styleFingerprint = computeStyleFingerprint(props.markdownStyle),
      .fontScale = fontScale,
  };
}

/**
 * Thread-safe global measurement cache using an LRU (Least Recently Used) strategy.
 * This ensures O(1) lookups while automatically discarding the oldest entries.
 */
class MeasurementCache {
public:
  struct CacheEntry {
    MeasurementCacheKey key;
    CachedSize size;
  };

  static MeasurementCache &shared()
  {
    static MeasurementCache instance;
    return instance;
  }

  bool get(const MeasurementCacheKey &key, CachedSize &outSize)
  {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = map_.find(key);
    if (it == map_.end()) {
      return false;
    }

    list_.splice(list_.begin(), list_, it->second);

    outSize = it->second->size;
    return true;
  }

  void set(const MeasurementCacheKey &key, CachedSize size)
  {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = map_.find(key);
    if (it != map_.end()) {
      it->second->size = size;
      list_.splice(list_.begin(), list_, it->second);
      return;
    }

    list_.push_front({key, size});
    map_[key] = list_.begin();

    if (map_.size() > kMaxEntries) {
      auto &lastEntry = list_.back();
      map_.erase(lastEntry.key);
      list_.pop_back();
    }
  }

private:
  MeasurementCache() = default;

  static constexpr size_t kMaxEntries = 512;
  mutable std::mutex mutex_;

  std::list<CacheEntry> list_;
  std::unordered_map<MeasurementCacheKey, std::list<CacheEntry>::iterator, MeasurementCacheKeyHash> map_;
};

} // namespace facebook::react