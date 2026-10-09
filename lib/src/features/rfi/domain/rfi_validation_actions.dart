import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_row.dart';

const int rfiValidationCommentMaxLength = 500;

const String rfiValidationRemarkPlaceholder = '-- Select --';

const List<String> rfiValidationRemarkOptions = <String>[
  rfiValidationRemarkPlaceholder,
  'NONO',
  'NONOC(C)',
  'NOR',
  'OTHERS',
];

enum RfiValidationDecision {
  approve('Approve', 'APPROVED'),
  reject('Reject', 'REJECTED'),
  rectify('Rectify', 'Returned_For_Clarification');

  const RfiValidationDecision(this.label, this.action);

  final String label;
  final String action;
}

enum RfiValidationOutcome { approved, returned, rejected, open }

RfiValidationOutcome rfiValidationOutcome(String? status) {
  final String raw = status?.trim() ?? '';
  final String upper = raw.toUpperCase();
  if (upper == 'APPROVED') {
    return RfiValidationOutcome.approved;
  }
  if (upper == 'REJECTED') {
    return RfiValidationOutcome.rejected;
  }
  if (raw == 'Returned_For_Clarification' ||
      upper == 'RETURNED_FOR_CLARIFICATION') {
    return RfiValidationOutcome.returned;
  }
  return RfiValidationOutcome.open;
}

String? rfiValidationStatusText(String? status) {
  return switch (rfiValidationOutcome(status)) {
    RfiValidationOutcome.approved => 'APPROVED',
    RfiValidationOutcome.rejected => 'REJECTED',
    RfiValidationOutcome.returned => 'Returned_For_Clarification',
    RfiValidationOutcome.open => null,
  };
}

List<RfiValidationDecision> rfiValidationDecisions(String? status) {
  if (rfiValidationOutcome(status) != RfiValidationOutcome.open) {
    return const <RfiValidationDecision>[];
  }
  return const <RfiValidationDecision>[
    RfiValidationDecision.approve,
    RfiValidationDecision.reject,
    RfiValidationDecision.rectify,
  ];
}

String rfiValidationSelectedRemark(String? remarks) {
  final String text = remarks?.trim() ?? '';
  for (final String option in rfiValidationRemarkOptions) {
    if (option == rfiValidationRemarkPlaceholder) {
      continue;
    }
    if (option == text) {
      return option;
    }
  }
  return rfiValidationRemarkPlaceholder;
}

bool rfiValidationRemarkChosen(String? remarks) {
  final String text = remarks?.trim() ?? '';
  return text.isNotEmpty && text != rfiValidationRemarkPlaceholder;
}

String clampRfiValidationComment(String? comment) {
  final String text = comment ?? '';
  if (text.length <= rfiValidationCommentMaxLength) {
    return text;
  }
  return text.substring(0, rfiValidationCommentMaxLength);
}

Map<String, String>? rfiValidationFormFields({
  required RfiValidationRow row,
  required String remarks,
  required String comment,
  required RfiValidationDecision decision,
}) {
  if (!rfiValidationRemarkChosen(remarks)) {
    return null;
  }
  final String clipped = clampRfiValidationComment(comment);
  return <String, String>{
    'long_rfi_id': row.longRfiId ?? '',
    'long_rfi_validate_id': row.longRfiValidateId?.toString() ?? '',
    'remarks': remarks.trim(),
    'comment': clipped,
    'action': decision.action,
  };
}
