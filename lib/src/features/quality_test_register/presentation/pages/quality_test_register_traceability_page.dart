import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class QualityTestRegisterTraceabilityPage extends ConsumerStatefulWidget {
  const QualityTestRegisterTraceabilityPage({
    super.key,
    required this.obligationId,
  });

  static const String routeName = 'forms-quality-test-register-traceability';

  static String locationFor(int obligationId) {
    return '/module/quality/test-register/obligation/$obligationId/traceability';
  }

  final int obligationId;

  @override
  ConsumerState<QualityTestRegisterTraceabilityPage> createState() =>
      _QualityTestRegisterTraceabilityPageState();
}

class _QualityTestRegisterTraceabilityPageState
    extends ConsumerState<QualityTestRegisterTraceabilityPage> {
  Object? _error;
  bool _loading = true;
  Map<String, dynamic> _data = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Response<dynamic> response = await ref
          .read(dioProvider)
          .get<dynamic>(
            ApiConstants.qualityTestObligationTraceabilityPath(
              widget.obligationId,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = _asMap(response.data);
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traceability')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: _loading),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _error is DioException
                    ? userFriendlyErrorMessage(_error! as DioException)
                    : _error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data.isEmpty) {
      return const Center(child: Text('No traceability data.'));
    }
    final AppPalette palette = AppPalette.of(context);
    final List<MapEntry<String, dynamic>> entries = _data.entries.toList(
      growable: false,
    );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, dynamic> entry = entries[index];
        return Card(
          color: palette.cardSurface,
          child: ListTile(
            title: Text(
              _label(entry.key),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              _value(entry.value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final Map<String, dynamic>? nested = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : null;
      return nested ?? raw;
    }
    if (raw is Map) {
      return raw.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }

  String _label(String key) {
    final String spaced = key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ');
    if (spaced.isEmpty) {
      return key;
    }
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _value(dynamic value) {
    if (value == null) {
      return '—';
    }
    if (value is List && value.length >= 3 && value[0] is num) {
      final String y = value[0].toString();
      final String m = value[1].toString().padLeft(2, '0');
      final String d = value[2].toString().padLeft(2, '0');
      return '$d-$m-$y';
    }
    if (value is Map || value is List) {
      return value.toString();
    }
    final String text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }
}
