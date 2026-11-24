import '../../domain/models/registration_field.dart';
import '../../domain/validation/registration_validator.dart';

class ClientRegistrationRequest {
  ClientRegistrationRequest(Map<RegistrationField, String> values)
    : _values = Map.unmodifiable(values);

  final Map<RegistrationField, String> _values;

  Map<String, Object> toJson() {
    final body = <String, Object>{};
    final address = <String, Object>{};
    for (final field in RegistrationField.values) {
      final apiName = field.apiName;
      if (apiName == null) continue;
      final raw = _values[field] ?? '';
      var value = field.secret ? raw : raw.trim();
      if (field.optional && value.isEmpty) continue;
      if (field == RegistrationField.curp || field == RegistrationField.rfc) {
        value = value.toUpperCase();
      }
      if (field == RegistrationField.birthDate) {
        final date = RegistrationValidator.parseBirthDate(value);
        if (date == null) throw const FormatException('Fecha inválida');
        value =
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }
      final Object encoded = field == RegistrationField.monthlyIncome
          ? num.parse(value.replaceAll(',', '.'))
          : value;
      if (apiName.startsWith('domicilio.')) {
        address[apiName.substring('domicilio.'.length)] = encoded;
      } else {
        body[apiName] = encoded;
      }
    }
    body['domicilio'] = address;
    return body;
  }
}
