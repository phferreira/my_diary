import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_diary/core/value_objects/diary_query.dart';

class DiarySearchField extends StatelessWidget {
  const DiarySearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 40,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
      ],
      validator: DiaryQuery.validate,
      decoration: const InputDecoration(
        labelText: 'Encontrar diário',
        hintText: 'Digite o nome do diário',
        border: OutlineInputBorder(),
      ),
    );
  }
}
