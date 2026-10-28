import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/contracts/data/datasources/contract_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_form.dart';

final contractFormMasterProvider =
    FutureProvider.autoDispose<ContractFormMaster>((ref) {
      return ref.watch(contractRemoteDataSourceProvider).fetchAddFormMaster();
    });
