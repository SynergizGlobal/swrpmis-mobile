import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';

void main() {
  test('Submit uploads only new phone PDFs, never saved server paths', () {
    const List<RfiLocalSupportingDoc> docs = <RfiLocalSupportingDoc>[
      RfiLocalSupportingDoc(
        path: '/home/smt/git/swrpmis_qa/Rfi-Storage/docs/old.pdf',
        description: 'saved earlier',
        onServer: true,
      ),
      RfiLocalSupportingDoc(
        path: '/var/mobile/Containers/Data/tmp/new.pdf',
        description: 'testing 123',
      ),
      RfiLocalSupportingDoc(path: 'https://example.org/remote.pdf'),
    ];
    final List<RfiLocalSupportingDoc> uploads = rfiSupportingUploads(docs);
    expect(uploads, hasLength(1));
    expect(uploads.single.description, 'testing 123');
  });

  test('editing a description keeps the document on the server', () {
    const RfiLocalSupportingDoc saved = RfiLocalSupportingDoc(
      path: '/home/x.pdf',
      onServer: true,
    );
    expect(saved.copyWith(description: 'new').onServer, isTrue);
  });

  test('saved supporting docs parse from a comma-joined string', () {
    final RfiInspectionDetailRfi rfi = RfiInspectionDetails.fromJson(
      <String, dynamic>{
        'rfi': <String, dynamic>{
          'id': 105,
          'conSupDocs': '/home/a.pdf, /home/b.pdf',
        },
        'enclosures': <dynamic>[],
        'measurements': <dynamic>[],
      },
    ).rfi;
    expect(rfi.conSupDocs.map((RfiSupportingDocument d) => d.path), <String>[
      '/home/a.pdf',
      '/home/b.pdf',
    ]);
  });
}
