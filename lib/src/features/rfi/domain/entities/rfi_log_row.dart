class RfiLogRow {
  const RfiLogRow({
    required this.id,
    required this.status,
    required this.contract,
    required this.structure,
    required this.project,
    required this.rfiCategory,
    required this.rfiDescription,
    required this.rfiId,
    required this.nameOfRepresentative,
    required this.person,
    required this.dateRaised,
    required this.conRespondedDate,
    required this.enggRespondedDate,
    required this.notes,
    required this.txnId,
    required this.validationStatus,
  });

  final int? id;
  final String status;
  final String contract;
  final String structure;
  final String project;
  final String rfiCategory;
  final String rfiDescription;
  final String rfiId;
  final String nameOfRepresentative;
  final String person;
  final String dateRaised;
  final String conRespondedDate;
  final String enggRespondedDate;
  final String notes;
  final String txnId;
  final String validationStatus;

  String get statusLabel =>
      rfiLogStatusLabel(status, validationStatus: validationStatus);

  bool get canDownload => rfiId.trim().isNotEmpty && txnId.trim().isNotEmpty;

  factory RfiLogRow.fromJson(Map<String, dynamic> json) {
    return RfiLogRow(
      id: _readId(json['id']),
      status: _text(json['status']),
      contract: _text(json['contract']),
      structure: _text(json['structure']),
      project: _text(json['project']),
      rfiCategory: _text(json['rfiCategory']),
      rfiDescription: _text(json['rfiDescription']),
      rfiId: _text(json['rfiId']),
      nameOfRepresentative: _text(json['nameOfRepresentative']),
      person: _text(json['person']),
      dateRaised: _text(json['dateRaised']),
      conRespondedDate: _text(json['conRespondedDate']),
      enggRespondedDate: _text(json['enggRespondedDate']),
      notes: _text(json['notes']),
      txnId: _firstText(json, const <String>[
        'txnId',
        'txnID',
        'transactionId',
      ]),
      validationStatus: _text(json['validationStatus']),
    );
  }
}

String rfiLogStatusLabel(String status, {String? validationStatus}) {
  final String raw = status.trim();
  if (raw.isEmpty) {
    return '—';
  }
  final String upper = raw.toUpperCase();
  final String validation = (validationStatus ?? '').trim().toUpperCase();
  if (upper == 'INSPECTION_DONE' && validation == 'REJECTED') {
    return 'Rejected';
  }
  if (upper == 'INSPECTION_DONE') {
    return 'Closed';
  }
  if (upper == 'CREATED' || upper == 'OPEN') {
    return 'Open';
  }
  if (upper == 'DELETED') {
    return 'Deleted';
  }
  if (upper == 'REJECTED') {
    return 'Rejected';
  }
  if (upper == 'UNDER_CON_RECTIFICATION') {
    return 'Under con. rectification';
  }
  if (upper == 'UNDER_ENGG_RECTIFICATION') {
    return 'Under engg. rectification';
  }
  return raw.replaceAll('_', ' ');
}

String rfiLogCell(String value) {
  final String text = value.trim();
  if (text.isEmpty) {
    return '—';
  }
  return text;
}

int? _readId(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String text = _text(json[key]);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}
