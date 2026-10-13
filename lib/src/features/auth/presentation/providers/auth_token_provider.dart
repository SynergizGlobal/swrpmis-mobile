import 'package:flutter_riverpod/flutter_riverpod.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

/// True while an SWR login session is active (cookie-based; JWT may be empty).
final swrSessionActiveProvider = StateProvider<bool>((ref) => false);
