/// Whether to use the Bidi algorithm to detect RTL text.
const bool useBidi = bool.fromEnvironment('use_bidi', defaultValue: true);

/// Whether to use the Arabic algorithm.
// Certificate Studio always needs OpenType Arabic shaping in local and
// release builds; do not depend on an external dart-define for correctness.
const bool useArabic = bool.fromEnvironment('use_arabic', defaultValue: true);
