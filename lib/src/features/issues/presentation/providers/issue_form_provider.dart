import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/issues/data/datasources/issue_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_form.dart';

final issueFormMasterProvider = FutureProvider.autoDispose
    .family<IssueFormMaster, String>((ref, String issueId) {
      return ref
          .watch(issueRemoteDataSourceProvider)
          .getAddIssueFormMaster(issueId);
    });

final issueDetailProvider = FutureProvider.autoDispose
    .family<IssueDetail, String>((ref, String issueId) {
      return ref.watch(issueRemoteDataSourceProvider).getIssueDetail(issueId);
    });
