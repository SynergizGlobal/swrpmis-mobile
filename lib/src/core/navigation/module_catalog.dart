import 'package:flutter/material.dart';

enum ModuleGroup { works, updateForms, reports, more }

class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.routePath,
    required this.group,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
  final String routePath;
  final ModuleGroup group;
}

class ModuleCatalog {
  const ModuleCatalog._();

  static const List<AppModule> all = <AppModule>[
    AppModule(
      id: 'structures',
      title: 'Structures',
      subtitle: 'Works and structure inventory',
      icon: Icons.domain_rounded,
      routeName: 'works-structures',
      routePath: '/module/structures',
      group: ModuleGroup.works,
    ),
    AppModule(
      id: 'bridges',
      title: 'Bridges',
      subtitle: 'Bridge records and viewer',
      icon: Icons.linear_scale_rounded,
      routeName: 'works-bridges',
      routePath: '/module/bridges',
      group: ModuleGroup.works,
    ),
    AppModule(
      id: 'projects',
      title: 'Projects',
      subtitle: 'Project list, types and summaries',
      icon: Icons.groups_rounded,
      routeName: 'works-projects',
      routePath: '/module/projects',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'works-forms',
      title: 'Works',
      subtitle: 'Structure and work updates',
      icon: Icons.construction_rounded,
      routeName: 'forms-works',
      routePath: '/module/works-forms',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'contracts',
      title: 'Contracts/Tenders',
      subtitle: 'Tenders, BG and contract status',
      icon: Icons.draw_rounded,
      routeName: 'forms-contracts',
      routePath: '/module/contracts',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'p6',
      title: 'Execution & Monitoring',
      subtitle: 'Activities, actuals and progress updates',
      icon: Icons.stairs_rounded,
      routeName: 'forms-p6',
      routePath: '/module/p6',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'design',
      title: 'Design & Drawing',
      subtitle: 'Design status and drawing files',
      icon: Icons.architecture_rounded,
      routeName: 'forms-design',
      routePath: '/module/design',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'issues',
      title: 'Issues',
      subtitle: 'Track and update site issues',
      icon: Icons.warning_amber_rounded,
      routeName: 'forms-issues',
      routePath: '/module/issues',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'dms',
      title: 'DMS',
      subtitle: 'Document folders and uploads',
      icon: Icons.file_copy_rounded,
      routeName: 'forms-dms',
      routePath: '/module/dms',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'quality',
      title: 'Quality Inspections',
      subtitle: 'Inspection records and NCR',
      icon: Icons.manage_search_rounded,
      routeName: 'forms-quality',
      routePath: '/module/quality',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'land',
      title: 'Land Acquisition',
      subtitle: 'Land acquisition process and status',
      icon: Icons.handshake_rounded,
      routeName: 'forms-land',
      routePath: '/module/land',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'utility',
      title: 'Utility Shifting',
      subtitle: 'Utility works and agencies',
      icon: Icons.electrical_services_rounded,
      routeName: 'forms-utility',
      routePath: '/module/utility',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'validate-data',
      title: 'Validate data',
      subtitle: 'Review and confirm submitted data',
      icon: Icons.verified_rounded,
      routeName: 'forms-validate-data',
      routePath: '/module/validate-data',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'report-generate',
      title: 'Generate report',
      subtitle: 'Build a custom PMIS report',
      icon: Icons.picture_as_pdf_rounded,
      routeName: 'reports-generate',
      routePath: '/module/report-generate',
      group: ModuleGroup.reports,
    ),
    AppModule(
      id: 'report-activities',
      title: 'Activities export',
      subtitle: 'Progress and TPC status reports',
      icon: Icons.table_chart_rounded,
      routeName: 'reports-activities',
      routePath: '/module/report-activities',
      group: ModuleGroup.reports,
    ),
    AppModule(
      id: 'report-issues',
      title: 'Issues report',
      subtitle: 'Pending and summary issue reports',
      icon: Icons.assignment_late_rounded,
      routeName: 'reports-issues',
      routePath: '/module/report-issues',
      group: ModuleGroup.reports,
    ),
    AppModule(
      id: 'report-contracts',
      title: 'Contract reports',
      subtitle: 'BG, insurance and contractual letters',
      icon: Icons.request_quote_rounded,
      routeName: 'reports-contracts',
      routePath: '/module/report-contracts',
      group: ModuleGroup.reports,
    ),
    AppModule(
      id: 'rdso',
      title: 'RDSO drawings',
      subtitle: 'Digital library and search',
      icon: Icons.menu_book_rounded,
      routeName: 'more-rdso',
      routePath: '/module/rdso',
      group: ModuleGroup.more,
    ),
    AppModule(
      id: 'rdso-revision',
      title: 'RDSO revision monitor',
      subtitle: 'Track drawing revision status',
      icon: Icons.update_rounded,
      routeName: 'more-rdso-revision',
      routePath: '/module/rdso-revision',
      group: ModuleGroup.more,
    ),
    AppModule(
      id: 'admin',
      title: 'Admin',
      subtitle: 'Users, roles and access',
      icon: Icons.admin_panel_settings_rounded,
      routeName: 'more-admin',
      routePath: '/module/admin',
      group: ModuleGroup.more,
    ),
    AppModule(
      id: 'rfi',
      title: 'RFI',
      subtitle: 'Inspections, logs and validation',
      icon: Icons.fact_check_rounded,
      routeName: 'more-rfi',
      routePath: '/module/rfi',
      group: ModuleGroup.more,
    ),
    AppModule(
      id: 'mail',
      title: 'Mail',
      subtitle: 'Inbox, drafts and correspondence',
      icon: Icons.mail_rounded,
      routeName: 'more-mail',
      routePath: '/module/mail',
      group: ModuleGroup.more,
    ),
    AppModule(
      id: 'help',
      title: 'Help & support',
      subtitle: 'Chat, FAQs and assistance',
      icon: Icons.headset_mic_rounded,
      routeName: 'more-help',
      routePath: '/module/help',
      group: ModuleGroup.more,
    ),
  ];

  static List<AppModule> byGroup(ModuleGroup group) {
    return all.where((AppModule module) => module.group == group).toList();
  }
}
