import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../controllers/registration_form_controller.dart';

class RegistrationTextField extends StatelessWidget {
  const RegistrationTextField({
    super.key,
    required this.form,
    required this.field,
    required this.label,
    this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.icon,
    this.suffix,
    this.prefixText,
    this.suffixText,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.inlineLabel = false,
    this.obscureText = false,
    this.inputFormatters,
  });

  final RegistrationFormController form;
  final RegistrationField field;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final IconData? icon;
  final Widget? suffix;
  final String? prefixText;
  final String? suffixText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final bool inlineLabel;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final error = form.error(field);
    final input = TextField(
      controller: form[field],
      focusNode: form.focusNode(field),
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      textInputAction: TextInputAction.next,
      readOnly: readOnly,
      obscureText: obscureText,
      onTap: onTap,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      autocorrect: !field.secret && capitalization == TextCapitalization.words,
      enableSuggestions: !field.secret,
      style: const TextStyle(fontSize: 16, color: ink),
      decoration: InputDecoration(
        labelText: inlineLabel ? null : label,
        hintText: hint,
        error: !inlineLabel && error != null ? FieldError(error) : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: icon == null ? null : Icon(icon, color: action, size: 22),
        suffixIcon: suffix,
        suffixIconConstraints: inlineLabel
            ? const BoxConstraints(minWidth: 24, minHeight: 24)
            : null,
        prefixText: prefixText,
        suffixText: suffixText,
        filled: !inlineLabel,
        isDense: inlineLabel,
        border: inlineLabel ? InputBorder.none : null,
        enabledBorder: inlineLabel ? InputBorder.none : null,
        focusedBorder: inlineLabel ? InputBorder.none : null,
        contentPadding: inlineLabel
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w400),
      ),
    );
    return KeyedSubtree(
      key: form.key(field),
      child: inlineLabel
          ? _InlineField(label: label, error: error, child: input)
          : input,
    );
  }
}

class RegistrationSelect extends StatelessWidget {
  const RegistrationSelect({
    super.key,
    required this.form,
    required this.field,
    required this.label,
    required this.options,
    this.inlineLabel = false,
  });

  final RegistrationFormController form;
  final RegistrationField field;
  final String label;
  final List<String> options;
  final bool inlineLabel;

  @override
  Widget build(BuildContext context) {
    final error = form.error(field);
    final input = ValueListenableBuilder(
      valueListenable: form[field],
      builder: (context, value, child) => DropdownButtonFormField<String>(
        key: ValueKey(value.text),
        initialValue: options.contains(value.text) ? value.text : null,
        focusNode: form.focusNode(field),
        isExpanded: true,
        hint: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Selecciona', style: TextStyle(color: muted)),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: action),
        decoration: InputDecoration(
          labelText: inlineLabel ? null : label,
          error: !inlineLabel && error != null ? FieldError(error) : null,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: !inlineLabel,
          isDense: inlineLabel,
          border: inlineLabel ? InputBorder.none : null,
          enabledBorder: inlineLabel ? InputBorder.none : null,
          focusedBorder: inlineLabel ? InputBorder.none : null,
          contentPadding: inlineLabel
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (selection) {
          if (selection != null) form[field].text = selection;
        },
      ),
    );
    return KeyedSubtree(
      key: form.key(field),
      child: inlineLabel
          ? _InlineField(label: label, error: error, child: input)
          : input,
    );
  }
}

class _InlineField extends StatefulWidget {
  const _InlineField({required this.label, required this.child, this.error});

  final String label;
  final Widget child;
  final String? error;

  @override
  State<_InlineField> createState() => _InlineFieldState();
}

class _InlineFieldState extends State<_InlineField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: InputDecorator(
        isFocused: _focused,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
          error: widget.error == null ? null : FieldError(widget.error!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 5),
            widget.child,
          ],
        ),
      ),
    ),
  );
}

class RegistrationFieldPair extends StatelessWidget {
  const RegistrationFieldPair({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });

  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(16) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 20), second],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 12),
            Expanded(flex: secondFlex, child: second),
          ],
        ),
      );
    },
  );
}

class RegistrationFieldList extends StatelessWidget {
  const RegistrationFieldList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const SizedBox(height: 22),
        children[index],
      ],
    ],
  );
}

class RegistrationHelp extends StatelessWidget {
  const RegistrationHelp(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: const TextStyle(color: muted, fontSize: 14, height: 1.4),
    ),
  );
}
