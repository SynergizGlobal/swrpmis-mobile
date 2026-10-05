class ExecutionProgressSegment {
  const ExecutionProgressSegment({
    required this.project,
    required this.projectFromKm,
    required this.projectToKm,
    required this.contract,
    required this.contractName,
    required this.contractShortName,
    required this.contractor,
    required this.subStructure,
    required this.fromKm,
    required this.toKm,
    required this.plotFromKm,
    required this.plotToKm,
    required this.status,
    required this.progress,
    required this.barColor,
    required this.structureType,
    required this.progressDate,
    required this.projectSection,
  });

  final String project;
  final double projectFromKm;
  final double projectToKm;
  final String contract;
  final String contractName;
  final String contractShortName;
  final String contractor;
  final String subStructure;
  final double fromKm;
  final double toKm;
  final double plotFromKm;
  final double plotToKm;
  final String status;
  final double progress;
  final String barColor;
  final String structureType;
  final String progressDate;
  final String projectSection;

  bool get isPoint => (plotToKm - plotFromKm).abs() < 0.001;

  String get contractShortLabel {
    for (final String value in <String>[
      contractShortName,
      contractName,
      contract,
    ]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'NA';
  }

  String get contractorLabel => _orNa(contractor);

  String get structureTypeLabel => _orNa(structureType);

  String get structureLabel => _orNa(subStructure);

  String get chainageLabel =>
      '${fromKm.toStringAsFixed(3)} to ${toKm.toStringAsFixed(3)}';

  String get statusLabel {
    final String text = status.trim();
    if (text.isEmpty) {
      return 'NA';
    }
    return text.toUpperCase();
  }

  String get progressLabel => '${progress.toStringAsFixed(2)}%';

  static ExecutionProgressSegment? tryParse(Map<String, dynamic> json) {
    if (!_isNumber(json['fromKm'])) {
      return null;
    }
    final double fromKm = _toDouble(json['fromKm']);
    final double toKm = _isNumber(json['toKm'])
        ? _toDouble(json['toKm'])
        : fromKm;
    final _PlotKm plot = _plotKm(
      fromKm: fromKm,
      toKm: toKm,
      subStructure: _text(json['subStructure']),
    );
    return ExecutionProgressSegment(
      project: _text(json['project']),
      projectFromKm: _isNumber(json['projectFromKm'])
          ? _toDouble(json['projectFromKm'])
          : 0,
      projectToKm: _isNumber(json['projectToKm'])
          ? _toDouble(json['projectToKm'])
          : 0,
      contract: _text(json['contract']),
      contractName: _text(json['contract_name'] ?? json['contractName']),
      contractShortName: _text(json['contractShortName']),
      contractor: _text(json['contractor']),
      subStructure: _text(json['subStructure']),
      fromKm: fromKm,
      toKm: toKm,
      plotFromKm: plot.fromKm,
      plotToKm: plot.toKm,
      status: _text(json['status']),
      progress: _isNumber(json['progress']) ? _toDouble(json['progress']) : 0,
      barColor: _text(json['barColor']),
      structureType: _text(json['structureType']),
      progressDate: _text(json['progressDate']),
      projectSection: _text(json['projectSection']),
    );
  }

  static _PlotKm _plotKm({
    required double fromKm,
    required double toKm,
    required String subStructure,
  }) {
    final RegExpMatch? match = RegExp(
      r'from\s+([\d.]+)\s*km\s+to\s+([\d.]+)\s*km',
      caseSensitive: false,
    ).firstMatch(subStructure);
    if (match == null) {
      return _PlotKm(fromKm, toKm);
    }
    final double? parsedFrom = double.tryParse(match.group(1)!);
    final double? parsedTo = double.tryParse(match.group(2)!);
    if (parsedFrom == null || parsedTo == null) {
      return _PlotKm(fromKm, toKm);
    }
    return _PlotKm(parsedFrom, parsedTo);
  }
}

class _PlotKm {
  const _PlotKm(this.fromKm, this.toKm);

  final double fromKm;
  final double toKm;
}

String _orNa(String value) {
  final String text = value.trim();
  return text.isEmpty ? 'NA' : text;
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

bool _isNumber(Object? value) {
  if (value is num) {
    return true;
  }
  if (value == null) {
    return false;
  }
  return double.tryParse(value.toString().trim().replaceAll(',', '')) != null;
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim().replaceAll(',', '')) ?? 0;
}
