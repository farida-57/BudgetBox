class ExpenseValidationException implements Exception {
  const ExpenseValidationException(this.message, {this.code, this.fieldErrors = const {}});

  final String message;
  final String? code;
  final Map<String, String> fieldErrors;
}
