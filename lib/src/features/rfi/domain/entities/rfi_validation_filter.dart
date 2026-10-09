class RfiValidationFilter {
  const RfiValidationFilter({
    this.projectId = '',
    this.contractId = '',
    this.rfiCategory = '',
  });

  final String projectId;
  final String contractId;
  final String rfiCategory;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projectId': projectId,
      'contractId': contractId,
      'rfiCategory': rfiCategory,
    };
  }

  RfiValidationFilter withCategory(String category) {
    return RfiValidationFilter(rfiCategory: category);
  }

  RfiValidationFilter withProject(String project) {
    return RfiValidationFilter(rfiCategory: rfiCategory, projectId: project);
  }

  RfiValidationFilter withContract(String contract) {
    return RfiValidationFilter(
      rfiCategory: rfiCategory,
      projectId: projectId,
      contractId: contract,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RfiValidationFilter &&
        other.projectId == projectId &&
        other.contractId == contractId &&
        other.rfiCategory == rfiCategory;
  }

  @override
  int get hashCode => Object.hash(projectId, contractId, rfiCategory);
}
