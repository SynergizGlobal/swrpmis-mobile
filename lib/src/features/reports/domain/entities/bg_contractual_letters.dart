/// Reports → Contracts → BG Contractual Letters
/// (formId 1369 / bg-contractual-letters).
bool isBgContractualLettersReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1369') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('bg-contractual-letters') ||
      url.contains('generate-bg-contractual-letters')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name == 'bg contractual letters' ||
      name == 'list of contracts closer to bg expiry date';
}

/// One row from `POST /ajax/generate-bg-contractual-letters`.
class BgContractualLetterRow {
  const BgContractualLetterRow({
    this.contractId = '',
    this.contractShortName = '',
    this.contractorName = '',
    this.bgType = '',
    this.issuingBank = '',
    this.bgNumber = '',
    this.amount = '',
    this.expiryDate = '',
    this.status = '',
  });

  final String contractId;
  final String contractShortName;
  final String contractorName;
  final String bgType;
  final String issuingBank;
  final String bgNumber;
  final String amount;
  final String expiryDate;
  final String status;

  factory BgContractualLetterRow.fromJson(Map<String, dynamic> json) {
    return BgContractualLetterRow(
      contractId: _firstText(json, const <String>[
        'contract_id',
        'contractId',
        'contract_id_fk',
      ]),
      contractShortName: _firstText(json, const <String>[
        'contract_short_name',
        'contractShortName',
        'short_name',
        'contract_name',
      ]),
      contractorName: _firstText(json, const <String>[
        'contractor_name',
        'contractorName',
        'contractor',
      ]),
      bgType: _firstText(json, const <String>['bg_type', 'bgType', 'type']),
      issuingBank: _firstText(json, const <String>[
        'issuing_bank',
        'issuingBank',
        'bank_name',
        'bank',
      ]),
      bgNumber: _firstText(json, const <String>[
        'bg_number',
        'bgNumber',
        'bg_no',
        'bgNo',
      ]),
      amount: _firstText(json, const <String>[
        'amount',
        'amount_inr',
        'bg_amount',
        'Amount (INR)',
      ]),
      expiryDate: _firstText(json, const <String>[
        'expiry_date',
        'expiryDate',
        'bg_expiry_date',
        'bg_date',
      ]),
      status: _firstText(json, const <String>['status', 'bg_status']),
    );
  }
}

/// Parses list/table JSON flexibly (root list or nested DataTables shapes).
List<BgContractualLetterRow> parseBgContractualLetters(Object? data) {
  if (data is String) {
    final String trimmed = data.trimLeft();
    if (trimmed.startsWith('<') || trimmed.toLowerCase().startsWith('<!doctype')) {
      throw StateError(
        'Unexpected HTML response. BG Contractual Letters search is not ready.',
      );
    }
  }
  final List<Map<String, dynamic>> maps = _asMaps(data);
  return maps
      .map(BgContractualLetterRow.fromJson)
      .toList(growable: false);
}

List<Map<String, dynamic>> _asMaps(Object? data) {
  if (data is List) {
    // DataTables sometimes returns array-of-arrays; skip non-maps.
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'aaData',
      'data',
      'result',
      'records',
      'content',
      'list',
      'rows',
      'items',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    // Single object payload.
    if (map.keys.any(
      (String k) =>
          k.toLowerCase().contains('contract') ||
          k.toLowerCase().contains('bg'),
    )) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _text(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  return '$value'.trim();
}
