String? validateDescription(String desc) {
  if (desc.trim().isEmpty) return 'Descrição é obrigatória. ';
  return null;
}

String? validatePositiveAmount(double value) {
  if (value <= 0) return 'Valor deve ser maio que zero. ';
  return null;
}

String? validateIntallmentRange(int current, int total) {
  if (total <= 0) return 'Total de parcelas deve ser maio que zero. ';
  if (current <= 0 || current > total) {
    return 'Parcela atual deve estar entre 1 e $total';
  }
  return null;
}
