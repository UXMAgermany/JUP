import 'package:flutter/material.dart';

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    Widget? title,
    super.validator,
    void Function(bool?)? onChanged,
    bool? value,
    bool autovalidate = false,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<bool> state) {
           return CheckboxListTile(
             dense: state.hasError,
             title: title,
             value: value,
             onChanged: (bool? value) {
               state.didChange(value);
               state.validate();
               onChanged!(value);
             },
             subtitle: state.hasError
                 ? Builder(
                     builder: (BuildContext context) => Text(
                       state.errorText ?? "",
                       style: TextStyle(
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                   )
                 : null,
             controlAffinity: ListTileControlAffinity.leading,
           );
         },
       );
}
