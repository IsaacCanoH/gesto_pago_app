import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.label,
    this.secret = false,
    this.focusNode,
    this.hasError = false,
    this.enabled = true,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final bool secret;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) => Row(
              children: List.generate(
                6,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasError
                              ? danger
                              : index == value.text.length
                              ? action
                              : line,
                        ),
                      ),
                      child: Center(
                        child: index >= value.text.length
                            ? null
                            : secret
                            ? const Icon(Icons.circle, size: 9, color: ink)
                            : Text(
                                value.text[index],
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: secret,
            autofillHints: autofillHints,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
