double parsePtBrToDouble(String raw) {
  final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
