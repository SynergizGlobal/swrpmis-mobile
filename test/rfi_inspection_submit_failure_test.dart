import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';

void main() {
  test('failed submit says the draft was saved', () {
    final String message = rfiSubmitFailureMessage(
      RfiSubmitFailure(StateError('Server error'), draftSaved: true),
    );
    expect(message, contains('Server error'));
    expect(message, contains('saved as a draft'));
  });

  test('failed submit says when the draft backup also failed', () {
    final String message = rfiSubmitFailureMessage(
      RfiSubmitFailure(StateError('Server error'), draftSaved: false),
    );
    expect(message, contains('could not be saved either'));
  });

  test('other errors keep the plain message', () {
    expect(rfiSubmitFailureMessage(StateError('boom')), contains('boom'));
  });
}
