import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_diary/core/value_objects/diary_query.dart';
import 'package:my_diary/ui/design_system/widgets/app_text_form_field.dart';

class DiarySearchField extends StatelessWidget {
  const DiarySearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: controller,
      maxLength: 40,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
      ],
      validator: DiaryQuery.validate,
      label: 'Encontrar diário',
      hint: 'Digite o nome do diário',
    );
  }
}
