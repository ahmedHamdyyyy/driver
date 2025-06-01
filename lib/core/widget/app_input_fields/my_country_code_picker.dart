import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

class CustomCountryCodePicker extends StatelessWidget {
  final TextEditingController codeController;
  const CustomCountryCodePicker({super.key, required this.codeController});
  @override
  Widget build(BuildContext context) {
    return CountryCodePicker(
      onChanged: (CountryCode code) {
        codeController.text = code.dialCode ?? "";
      },
      // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
      initialSelection: '+20',
      favorite: const [
        '+20',
      ],
      showFlag: true,
      // optional. Shows only country name and flag
      showCountryOnly: false,
      // optional. Shows only country name and flag when popup is closed.
      showOnlyCountryWhenClosed: false,
      showFlagMain: true,
      // optional. aligns the flag and the Text left
      alignLeft: false,
      padding: const EdgeInsets.all(0),
      // showDropDownButton: true,
    );
  }
}
