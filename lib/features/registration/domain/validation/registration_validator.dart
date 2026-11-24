import 'dart:convert';
import 'dart:math' as math;

import '../models/registration_field.dart';

class RegistrationValidator {
  RegistrationValidator({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final _letters = RegExp(r'^[\p{L} ]+$', unicode: true);
  static final _curp = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$');
  static final _rfc = RegExp(r'^[A-Z&Ñ]{4}[0-9]{6}[A-Z0-9]{3}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phone = RegExp(r'^[0-9]{10}$');
  static final _pin = RegExp(r'^[0-9]{6}$');
  static final _income = RegExp(r'^[0-9]{1,13}(?:[.,][0-9]{1,2})?$');
  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _lower = RegExp(r'\p{Ll}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static DateTime? parseBirthDate(String value) {
    final match = RegExp(r'^([0-9]{2})/([0-9]{2})/([0-9]{4})$')
        .firstMatch(value);
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  String? validate(
    RegistrationField field,
    Map<RegistrationField, String> values,
  ) {
    final raw = values[field] ?? '';
    final value = field.secret ? raw : raw.trim();
    if (value.isEmpty) {
      return field.optional ? null : 'Este campo es obligatorio.';
    }
    if ({
      RegistrationField.name,
      RegistrationField.middleName,
      RegistrationField.paternalSurname,
      RegistrationField.maternalSurname,
    }.contains(field)) {
      if (value.length < 2 || value.length > 50) {
        return 'Ingresa entre 2 y 50 caracteres.';
      }
      return _letters.hasMatch(value) ? null : 'Usa solo letras y espacios.';
    }

    return switch (field) {
      RegistrationField.birthDate => _validateBirthDate(value),
      RegistrationField.curp =>
        _curp.hasMatch(value.toUpperCase())
            ? null
            : 'Ingresa una CURP válida de 18 caracteres.',
      RegistrationField.rfc =>
        _rfc.hasMatch(value.toUpperCase())
            ? null
            : 'Ingresa un RFC válido de 13 caracteres.',
      RegistrationField.email =>
        value.length <= 100 && _email.hasMatch(value)
            ? null
            : 'Ingresa un correo electrónico válido de hasta 100 caracteres.',
      RegistrationField.mobilePhone || RegistrationField.alternatePhone =>
        _phone.hasMatch(value) ? null : 'Ingresa exactamente 10 dígitos.',
      RegistrationField.postalCode =>
        RegExp(r'^[0-9]{5}$').hasMatch(value)
            ? null
            : 'Ingresa exactamente 5 dígitos.',
      RegistrationField.monthlyIncome => _validateIncome(value),
      RegistrationField.password => _validatePassword(value),
      RegistrationField.passwordConfirmation =>
        value == values[RegistrationField.password]
            ? null
            : 'Las contraseñas no coinciden.',
      RegistrationField.pin =>
        _pin.hasMatch(value) ? null : 'Ingresa exactamente seis dígitos.',
      RegistrationField.pinConfirmation =>
        !_pin.hasMatch(value)
            ? 'Ingresa exactamente seis dígitos.'
            : value == values[RegistrationField.pin]
            ? null
            : 'Los PIN no coinciden.',
      _ => _validateLength(field, value),
    };
  }

  String? _validateBirthDate(String value) {
    final date = parseBirthDate(value);
    if (date == null) return 'Selecciona una fecha de nacimiento válida.';
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    if (!date.isBefore(today)) return 'La fecha debe ser anterior a hoy.';
    final year = today.year - 18;
    final lastDay = DateTime(year, today.month + 1, 0).day;
    final cutoff = DateTime(year, today.month, math.min(today.day, lastDay));
    if (date.isAfter(cutoff)) return 'Debes tener 18 años o más.';
    return null;
  }

  String? _validateIncome(String value) {
    if (!_income.hasMatch(value)) {
      return 'Usa hasta 13 enteros y 2 decimales, sin separadores de miles.';
    }
    return num.parse(value.replaceAll(',', '.')) > 0
        ? null
        : 'Ingresa un importe mayor a cero.';
  }

  String? _validatePassword(String value) {
    if (value.length < 8) return 'Usa al menos 8 caracteres.';
    if (utf8.encode(value).length > 72) {
      return 'La contraseña es demasiado larga. Usa como máximo 72 bytes.';
    }
    if (value.contains('\n') ||
        value.contains('\r') ||
        !_upper.hasMatch(value) ||
        !_lower.hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !_symbol.hasMatch(value)) {
      return 'Incluye mayúscula, minúscula, número y símbolo.';
    }
    return null;
  }

  String? _validateLength(RegistrationField field, String value) {
    final max = switch (field) {
      RegistrationField.sex ||
      RegistrationField.maritalStatus ||
      RegistrationField.exteriorNumber ||
      RegistrationField.interiorNumber => 20,
      RegistrationField.nationality || RegistrationField.country => 60,
      RegistrationField.company || RegistrationField.street => 150,
      _ => 100,
    };
    return value.length <= max ? null : 'Usa como máximo $max caracteres.';
  }
}
