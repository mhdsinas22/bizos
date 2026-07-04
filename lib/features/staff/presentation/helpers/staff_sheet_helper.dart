import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/presentation/sheets/staff_form_sheet.dart';
import 'package:flutter/material.dart';

class StaffSheetHelper {
  static Future<void> showStaffForm({
    required BuildContext context,
    UserModel? staff,
    required VoidCallback onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffFormSheet(staff: staff, onSave: onSave),
    );
  }
}
