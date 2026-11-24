import 'package:flutter/material.dart';

import '../../data/models/client_registration_request.dart';
import '../../domain/models/registration_field.dart';
import '../../domain/validation/registration_validator.dart';

export '../../domain/models/registration_field.dart';

class RegistrationFormController extends ChangeNotifier {
  RegistrationFormController({RegistrationValidator? validator})
    : _validator = validator ?? RegistrationValidator() {
    this[RegistrationField.nationality].text = 'Mexicana';
    this[RegistrationField.country].text = 'México';
    for (final field in RegistrationField.values) {
      _lastText[field] = this[field].text;
      this[field].addListener(() => _changed(field));
    }
  }

  final RegistrationValidator _validator;
  final _controllers = {
    for (final field in RegistrationField.values)
      field: TextEditingController(),
  };
  final _keys = {
    for (final field in RegistrationField.values) field: GlobalKey(),
  };
  final _focusNodes = {
    for (final field in RegistrationField.values) field: FocusNode(),
  };
  final _errors = <RegistrationField, String>{};
  final _serverErrors = <RegistrationField, String>{};
  final _lastText = <RegistrationField, String>{};
  final _validated = <RegistrationField>{};

  TextEditingController operator [](RegistrationField field) =>
      _controllers[field]!;
  GlobalKey key(RegistrationField field) => _keys[field]!;
  FocusNode focusNode(RegistrationField field) => _focusNodes[field]!;
  String? error(RegistrationField field) => _errors[field];
  String text(RegistrationField field) => this[field].text.trim();

  String joined(Iterable<RegistrationField> fields, {String separator = ' '}) =>
      fields.map(text).where((value) => value.isNotEmpty).join(separator);

  Map<RegistrationField, String> get values => {
    for (final field in RegistrationField.values) field: this[field].text,
  };

  ClientRegistrationRequest get request => ClientRegistrationRequest(values);

  void _changed(RegistrationField field) {
    final text = this[field].text;
    if (_lastText[field] == text) return;
    _lastText[field] = text;
    _serverErrors.remove(field);
    final snapshot = values;
    final affected = {
      field,
      if (field == RegistrationField.password)
        RegistrationField.passwordConfirmation,
      if (field == RegistrationField.pin) RegistrationField.pinConfirmation,
    };
    var changed = false;
    for (final item in affected) {
      if (!_validated.contains(item)) continue;
      final before = _errors[item];
      final message =
          _serverErrors[item] ?? _validator.validate(item, snapshot);
      if (message == null) {
        _errors.remove(item);
      } else {
        _errors[item] = message;
      }
      changed = changed || before != message;
    }
    if (changed) notifyListeners();
  }

  bool validate(Iterable<RegistrationField> fields) {
    final snapshot = values;
    for (final field in fields) {
      _validated.add(field);
      final message =
          _serverErrors[field] ?? _validator.validate(field, snapshot);
      if (message == null) {
        _errors.remove(field);
      } else {
        _errors[field] = message;
      }
    }
    notifyListeners();
    return fields.every((field) => !_errors.containsKey(field));
  }

  void applyServerErrors(Map<RegistrationField, String> errors) {
    _validated.addAll(errors.keys);
    _serverErrors.addAll(errors);
    _errors.addAll(errors);
    notifyListeners();
  }

  RegistrationField? firstError(Iterable<RegistrationField> fields) {
    for (final field in fields) {
      if (_errors.containsKey(field)) return field;
    }
    return null;
  }

  void clearSecrets() {
    for (final field in RegistrationField.values.where(
      (field) => field.secret,
    )) {
      this[field].clear();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}
