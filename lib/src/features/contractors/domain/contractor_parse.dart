import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';

List<ContractorRow> parseContractorRows(dynamic data) {
  final List<ContractorRow> rows = <ContractorRow>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _first(json, const <String>[
      'contractorId',
      'contractor_id',
      'id',
    ]);
    final String name = _first(json, const <String>[
      'contractorName',
      'contractor_name',
      'name',
    ]);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    rows.add(
      ContractorRow(
        contractorId: id,
        contractorName: name,
        specialization: _first(json, const <String>[
          'specilaization', // backend typo
          'specialization',
          'specialisation',
        ]),
        address: _first(json, const <String>['address']),
        primaryContact: _first(json, const <String>[
          'primaryContact',
          'primary_contact',
        ]),
        phoneNumber: _first(json, const <String>[
          'phoneNumber',
          'phone_number',
          'phone',
        ]),
        email: _first(json, const <String>['email']),
        panNumber: _first(json, const <String>[
          'panNumber',
          'pan_number',
          'pan',
        ]),
        gstNumber: _first(json, const <String>[
          'gstNumber',
          'gst_number',
          'gst',
        ]),
        bankName: _first(json, const <String>['bankName', 'bank_name']),
        accountNo: _first(json, const <String>[
          'accountNo',
          'account_no',
          'accountNumber',
          'account_number',
        ]),
        ifscCode: _first(json, const <String>['ifscCode', 'ifsc_code', 'ifsc']),
        bankAddress: _first(json, const <String>[
          'bankAddress',
          'bank_address',
        ]),
        remarks: _first(json, const <String>['remarks', 'remark']),
        contractorShortCode: _first(json, const <String>[
          'contractorShortCode',
          'contractor_short_code',
          'shortCode',
          'short_code',
        ]),
        searchStr: _nullable(json['searchStr'] ?? json['search_str']),
      ),
    );
  }
  return rows;
}

List<String> parseContractorSpecializations(dynamic data) {
  if (data is List) {
    final List<String> out = <String>[];
    final Set<String> seen = <String>{};
    for (final dynamic item in data) {
      final String value = item is String
          ? item.trim()
          : item is Map
          ? _first(Map<String, dynamic>.from(item), const <String>[
              'name',
              'label',
              'value',
              'specialization',
              'specilaization',
            ])
          : item?.toString().trim() ?? '';
      if (value.isEmpty || !seen.add(value.toLowerCase())) {
        continue;
      }
      out.add(value);
    }
    return out;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'items',
      'specializations',
    ]) {
      if (map.containsKey(key)) {
        return parseContractorSpecializations(map[key]);
      }
    }
  }
  return const <String>[];
}

ContractorRow? parseContractorRow(dynamic data) {
  final List<ContractorRow> rows = parseContractorRows(data);
  if (rows.isEmpty) {
    return null;
  }
  return rows.first;
}

String parseContractorSaveMessage(
  dynamic data, {
  required String fallback,
}) {
  if (data is Map) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    final String message = _first(json, const <String>[
      'message',
      'msg',
      'statusMessage',
      'status_message',
    ]);
    if (message.isNotEmpty) {
      return message;
    }
    final String id = _first(json, const <String>[
      'contractorId',
      'contractor_id',
      'id',
    ]);
    if (id.isNotEmpty) {
      return '$fallback ($id)';
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return fallback;
}

String? contractorApiMessage(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    final String message = _first(json, const <String>[
      'message',
      'error',
      'errorMessage',
      'error_message',
      'msg',
    ]);
    return message.isEmpty ? null : message;
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

String? _nullable(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

String? _text(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? text = _text(json[key]);
    if (text != null) {
      return text;
    }
  }
  return '';
}

Iterable<Map<String, dynamic>> _maps(
  dynamic data, {
  List<String> listKeys = const <String>['data', 'result', 'items', 'aaData'],
}) sync* {
  if (data == null) {
    return;
  }
  if (data is List) {
    for (final dynamic item in data) {
      if (item is Map) {
        yield Map<String, dynamic>.from(item);
      }
    }
    return;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in listKeys) {
      if (map.containsKey(key)) {
        yield* _maps(map[key], listKeys: listKeys);
        return;
      }
    }
    yield map;
  }
}
