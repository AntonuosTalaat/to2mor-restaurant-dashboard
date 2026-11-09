// ══════════════════════════════════════════════
//  Validators - مدققات الحقول
//  Form field validators with Arabic messages
// ══════════════════════════════════════════════

class Validators {
  // ── Email Validator ──────────────────────────
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل البريد الإلكتروني';
    }

    // Remove whitespace
    value = value.trim();

    // Check for basic email format
    if (!value.contains('@')) {
      return 'بريد إلكتروني غير صحيح';
    }

    // Regex for more comprehensive email validation
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!regex.hasMatch(value)) {
      return 'بريد إلكتروني غير صحيح';
    }

    return null;
  }

  // ── Password Validator ───────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل كلمة المرور';
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  // ── Strong Password Validator ────────────────
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل كلمة المرور';
    }

    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }

    return null;
  }

  // ── Confirm Password Validator ───────────────
  static String? Function(String?) confirmPassword(
    String Function() passwordProvider,
  ) {
    return (String? value) {
      final confirm = value?.trim() ?? '';
      final password = passwordProvider().trim();

      if (confirm.isEmpty) {
        return 'أدخل تأكيد كلمة المرور';
      }

      if (confirm != password) {
        return 'كلمة المرور غير متطابقة';
      }

      return null;
    };
  }

  // ── Required Field Validator ─────────────────
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? 'أدخل $fieldName' : 'هذا الحقل مطلوب';
    }
    return null;
  }

  // ── Phone Number Validator ───────────────────
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم الهاتف';
    }

    // Remove spaces and special characters
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits and optional + at start
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleanValue)) {
      return 'رقم هاتف غير صحيح';
    }

    return null;
  }

  // ── Minimum Length Validator ─────────────────
  static String? Function(String?) minLength(int min, {String? fieldName}) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return fieldName != null ? 'أدخل $fieldName' : 'هذا الحقل مطلوب';
      }

      if (value.length < min) {
        return 'يجب أن يكون $min أحرف على الأقل';
      }

      return null;
    };
  }

  // ── Maximum Length Validator ─────────────────
  static String? Function(String?) maxLength(int max, {String? fieldName}) {
    return (String? value) {
      if (value != null && value.length > max) {
        return 'يجب ألا يتجاوز $max حرف';
      }
      return null;
    };
  }

  // ── Number Validator ─────────────────────────
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم';
    }

    if (double.tryParse(value) == null) {
      return 'أدخل رقم صحيح';
    }

    return null;
  }

  // ── Positive Number Validator ────────────────
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'أدخل رقم صحيح';
    }

    if (number <= 0) {
      return 'يجب أن يكون الرقم أكبر من صفر';
    }

    return null;
  }

  // ── Range Validator ──────────────────────────
  static String? Function(String?) range(double min, double max) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'أدخل رقم';
      }

      final number = double.tryParse(value);
      if (number == null) {
        return 'أدخل رقم صحيح';
      }

      if (number < min || number > max) {
        return 'يجب أن يكون الرقم بين $min و $max';
      }

      return null;
    };
  }

  // ── URL Validator ────────────────────────────
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رابط';
    }

    final regex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!regex.hasMatch(value)) {
      return 'رابط غير صحيح';
    }

    return null;
  }

  // ── Username Validator ───────────────────────
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل اسم المستخدم';
    }

    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }

    if (value.length > 20) {
      return 'اسم المستخدم يجب ألا يتجاوز 20 حرف';
    }

    // Only letters, numbers, underscore and dash
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'اسم المستخدم يجب أن يحتوي على حروف وأرقام فقط';
    }

    return null;
  }

  // ── Arabic Name Validator ────────────────────
  static String? arabicName(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل الاسم';
    }

    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }

    // Check if contains Arabic characters
    if (!RegExp(r'[\u0600-\u06FF\s]+').hasMatch(value)) {
      return 'الاسم يجب أن يكون بالعربية';
    }

    return null;
  }

  // ── Compose Multiple Validators ──────────────
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
