import 'package:bizos/features/staff/domain/enities/staff_business_entity.dart';

class StaffBusinessModel extends StaffBusinessEntity {
  const StaffBusinessModel({
    required super.id,
    required super.staffId,
    required super.businessId,
  });
  factory StaffBusinessModel.fromJson(Map<String, dynamic> json) {
    return StaffBusinessModel(
      id: json["id"],
      staffId: json["staff_id"],
      businessId: json["business_id"],
    );
  }
  Map<String, dynamic> toJson() {
    return {"id": id, "staff_id": staffId, "business_id": businessId};
  }
}
