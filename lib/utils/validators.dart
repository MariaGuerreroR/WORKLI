class Validators {
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < min) {
      return '$field debe tener al menos $min caracteres';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > max) {
      return '$field no puede exceder $max caracteres';
    }
    return null;
  }

  static String? budget(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Ingresa un valor numérico';
    if (parsed < 0) return 'El presupuesto no puede ser negativo';
    return null;
  }

  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    if (end.isBefore(start)) {
      return 'La fecha de fin debe ser posterior a la de inicio';
    }
    return null;
  }
}
