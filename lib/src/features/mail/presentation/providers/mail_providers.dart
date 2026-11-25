import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/document_repository_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_thread.dart';

final mailLabelsProvider = FutureProvider.autoDispose<List<MailLabel>>((
  ref,
) async {
  final MailRemoteDataSource ds = ref.watch(mailRemoteDataSourceProvider);
  return ds.fetchLabels();
});

final mailDashboardProvider = FutureProvider.autoDispose<MailDashboardData>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchDashboard();
});

final mailInboxProvider = FutureProvider.autoDispose<List<MailMessage>>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchInbox();
});

final repositoryItemsProvider = FutureProvider.autoDispose
    .family<List<RepositoryItem>, int?>((ref, int? folderId) async {
      final DocumentRepositoryRemoteDataSource ds = ref.watch(
        documentRepositoryRemoteDataSourceProvider,
      );
      if (folderId == null) {
        return ds.fetchRoot();
      }
      return ds.fetchFolder(folderId);
    });

final mailDraftsProvider = FutureProvider.autoDispose<List<MailMessage>>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchDrafts();
});

final mailSentProvider = FutureProvider.autoDispose<List<MailMessage>>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchSent();
});

final mailTrashProvider = FutureProvider.autoDispose<List<MailMessage>>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchTrash();
});

final mailStarredProvider = FutureProvider.autoDispose<List<MailMessage>>((
  ref,
) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchStarred();
});

final mailLabelMailsProvider = FutureProvider.autoDispose
    .family<List<MailMessage>, String>((ref, String labelName) async {
      return ref
          .watch(mailRemoteDataSourceProvider)
          .fetchLabelMails(labelName);
    });

final mailThreadProvider = FutureProvider.autoDispose
    .family<List<MailThreadMessage>, int>((ref, int mailId) async {
      return ref.watch(mailRemoteDataSourceProvider).fetchThread(mailId);
    });

class MailBadgeCounts {
  const MailBadgeCounts({required this.unreadInbox, required this.drafts});

  final int unreadInbox;
  final int drafts;
}

final mailBadgeCountsProvider = FutureProvider.autoDispose<MailBadgeCounts>((
  ref,
) async {
  final MailRemoteDataSource ds = ref.watch(mailRemoteDataSourceProvider);
  final List<MailMessage> inbox = await ds.fetchInbox();
  final List<MailMessage> drafts = await ds.fetchDrafts();
  final int unread = inbox.where((MailMessage m) => !m.read).length;
  return MailBadgeCounts(unreadInbox: unread, drafts: drafts.length);
});

Future<void> mailRefreshAll(WidgetRef ref) {
  ref.invalidate(mailDashboardProvider);
  ref.invalidate(mailInboxProvider);
  ref.invalidate(mailDraftsProvider);
  ref.invalidate(mailSentProvider);
  ref.invalidate(mailTrashProvider);
  ref.invalidate(mailStarredProvider);
  ref.invalidate(mailLabelsProvider);
  ref.invalidate(mailBadgeCountsProvider);
  // Bust family label caches too (autoDispose families keep last args).
  ref.invalidate(mailLabelMailsProvider);
  return Future<void>.value();
}

Future<MailLabel> mailCreateLabel(
  WidgetRef ref, {
  required String name,
  required String color,
}) async {
  final MailLabel label = await ref
      .read(mailRemoteDataSourceProvider)
      .createLabel(name: name, color: color);
  ref.invalidate(mailLabelsProvider);
  return label;
}

Future<String> mailToggleStar(
  WidgetRef ref, {
  required int mailId,
  required bool starred,
}) async {
  final String message = await ref
      .read(mailRemoteDataSourceProvider)
      .setStarred(mailId: mailId, starred: starred);
  await mailRefreshAll(ref);
  return message;
}

Future<String> mailMarkRead(
  WidgetRef ref, {
  required int mailId,
  required String userId,
}) async {
  final String message = await ref
      .read(mailRemoteDataSourceProvider)
      .markMailRead(mailId: mailId, userId: userId);
  ref.invalidate(mailInboxProvider);
  ref.invalidate(mailBadgeCountsProvider);
  ref.invalidate(mailDashboardProvider);
  ref.invalidate(mailStarredProvider);
  return message;
}

Future<String> mailTrashMessage(WidgetRef ref, {required int mailId}) async {
  final String message = await ref
      .read(mailRemoteDataSourceProvider)
      .moveToTrash(mailId: mailId);
  await mailRefreshAll(ref);
  return message;
}

Future<String> mailRestoreMessage(WidgetRef ref, {required int mailId}) async {
  final String message = await ref
      .read(mailRemoteDataSourceProvider)
      .restoreMail(mailId: mailId);
  await mailRefreshAll(ref);
  return message;
}

Future<String> mailPermanentDeleteMessage(
  WidgetRef ref, {
  required int mailId,
}) async {
  final String message = await ref
      .read(mailRemoteDataSourceProvider)
      .permanentDelete(mailId: mailId);
  await mailRefreshAll(ref);
  return message;
}

final mailComposeProjectsProvider =
    FutureProvider.autoDispose<List<MailComposeProject>>((ref) async {
  return ref.watch(mailRemoteDataSourceProvider).fetchComposeProjects();
});

final mailComposeContractsProvider = FutureProvider.autoDispose
    .family<List<MailComposeContract>, String>((ref, String projectId) async {
  final String id = projectId.trim();
  if (id.isEmpty) {
    return const <MailComposeContract>[];
  }
  return ref.watch(mailRemoteDataSourceProvider).fetchComposeContracts(id);
});

final mailComposeRecipientsProvider = FutureProvider.autoDispose
    .family<List<MailRecipient>, String>((ref, String contractShortName) async {
  final String shortName = contractShortName.trim();
  if (shortName.isEmpty) {
    return const <MailRecipient>[];
  }
  return ref
      .watch(mailRemoteDataSourceProvider)
      .fetchRecipientsByContract(shortName);
});

Future<MailDraftSaveResult> mailSaveDraft(
  WidgetRef ref, {
  required MailComposePayload payload,
  List<MailComposeAttachment> files = const <MailComposeAttachment>[],
}) async {
  final MailDraftSaveResult result = await ref
      .read(mailRemoteDataSourceProvider)
      .saveDraft(payload: payload, files: files);
  ref.invalidate(mailDraftsProvider);
  ref.invalidate(mailBadgeCountsProvider);
  ref.invalidate(mailDashboardProvider);
  return result;
}

Future<String> mailSend(
  WidgetRef ref, {
  required MailComposePayload payload,
  List<MailComposeAttachment> files = const <MailComposeAttachment>[],
  int? draftId,
}) async {
  final String message = await ref.read(mailRemoteDataSourceProvider).sendMail(
        payload: payload,
        files: files,
        draftId: draftId,
      );
  await mailRefreshAll(ref);
  return message;
}
