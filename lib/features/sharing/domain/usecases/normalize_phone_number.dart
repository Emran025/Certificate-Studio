/// Converts a phone value into the digits-only international format expected
/// by WhatsApp's Android JID intent extra. Unmarked numbers must be long enough
/// to include a country code; shorter local values are rejected to avoid routing
/// a PDF to the wrong person.
class NormalizePhoneNumber {
  const NormalizePhoneNumber();

  String? call(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final ascii = _convertArabicDigits(value.trim());
    final hasInternationalPrefix =
        ascii.startsWith('+') ||
        RegExp(r'^00').hasMatch(ascii.replaceAll(RegExp(r'^[\s(]+'), ''));
    var digits = ascii.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length < 8 || digits.length > 15) return null;
    if (!hasInternationalPrefix && digits.length < 11) return null;
    return digits;
  }

  String _convertArabicDigits(String value) =>
      value.replaceAllMapped(RegExp(r'[٠-٩۰-۹]'), (match) {
        final rune = match.group(0)!.runes.first;
        final digit = rune >= 0x06F0 ? rune - 0x06F0 : rune - 0x0660;
        return digit.toString();
      });
}
