class RfiValidatorOption {
  const RfiValidatorOption({
    required this.userId,
    required this.userName,
    required this.validateType,
  });

  final String userId;
  final String userName;
  final String validateType;

  String get label {
    final String type = validateType.trim();
    if (type.isEmpty) {
      return userName;
    }
    return '$userName ($type)';
  }

  @override
  bool operator ==(Object other) {
    return other is RfiValidatorOption &&
        other.userId == userId &&
        other.validateType == validateType;
  }

  @override
  int get hashCode => Object.hash(userId, validateType);

  factory RfiValidatorOption.fromJson(Map<String, dynamic> json) {
    return RfiValidatorOption(
      userId: _text(json['userId'] ?? json['sentToUserId']),
      userName: _text(json['userName'] ?? json['sentToUserName'] ?? json['name']),
      validateType: _text(
        json['validateType'] ?? json['validationType'] ?? json['type'],
      ),
    );
  }
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
