import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

String rfiInspectionUploadedBy(RfiUserRole role) {
  switch (role) {
    case RfiUserRole.contractor:
    case RfiUserRole.contractorRep:
      return 'CON';
    case RfiUserRole.engineer:
    case RfiUserRole.dyHodEngineer:
      return 'AE';
    case RfiUserRole.hod:
    case RfiUserRole.dyHod:
      return 'ENG';
    case RfiUserRole.superUser:
    case RfiUserRole.itAdmin:
    case RfiUserRole.unknown:
      return 'ENG';
  }
}

String rfiChecklistUploadedBy(RfiUserRole role) {
  if (role == RfiUserRole.contractor || role == RfiUserRole.contractorRep) {
    return 'CON';
  }
  return 'engg';
}

bool rfiIsContractorUploader(String? uploadedBy) {
  return uploadedBy?.trim().toUpperCase() == 'CON';
}

bool rfiIsEngineerUploader(String? uploadedBy) {
  final String value = uploadedBy?.trim().toUpperCase() ?? '';
  return value == 'ENG' ||
      value == 'ENGG' ||
      value == 'AE' ||
      value.startsWith('ENG');
}

bool rfiRoleIsContractorSide(RfiUserRole role) {
  return role == RfiUserRole.contractor || role == RfiUserRole.contractorRep;
}

bool rfiRoleIsEngineerSide(RfiUserRole role) {
  return role == RfiUserRole.engineer ||
      role == RfiUserRole.dyHodEngineer ||
      role == RfiUserRole.hod ||
      role == RfiUserRole.dyHod;
}
