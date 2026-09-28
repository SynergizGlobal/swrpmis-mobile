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
      id: 'projects',
      title: 'Projects',
      subtitle: 'Project list, types and summaries',
      icon: Icons.account_tree_rounded,
      routeName: 'works-projects',
      routePath: '/module/projects',
      group: ModuleGroup.works,
    ),
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
      id: 'project-form',
      title: 'Project form',
      subtitle: 'Add or update project details',
      icon: Icons.post_add_rounded,
      routeName: 'forms-project',
      routePath: '/module/project-form',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'structure-form',
      title: 'Structure form',
      subtitle: 'Update structure work progress',
      icon: Icons.handyman_rounded,
      routeName: 'forms-structure',
      routePath: '/module/structure-form',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'design',
      title: 'Design drawings',
      subtitle: 'Design status and drawing files',
      icon: Icons.architecture_rounded,
      routeName: 'forms-design',
      routePath: '/module/design',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'dms',
      title: 'Document management',
      subtitle: 'DMS folders and uploads',
      icon: Icons.snippet_folder_rounded,
      routeName: 'forms-dms',
      routePath: '/module/dms',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'issues',
      title: 'Issues',
      subtitle: 'Track and update site issues',
      icon: Icons.report_problem_rounded,
      routeName: 'forms-issues',
      routePath: '/module/issues',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'land',
      title: 'Land acquisition',
      subtitle: 'LA process and status',
      icon: Icons.map_rounded,
      routeName: 'forms-land',
      routePath: '/module/land',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'utility',
      title: 'Utility shifting',
      subtitle: 'Utility works and agencies',
      icon: Icons.electrical_services_rounded,
      routeName: 'forms-utility',
      routePath: '/module/utility',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'contracts',
      title: 'Contracts',
      subtitle: 'Tenders, BG and contract status',
      icon: Icons.assignment_rounded,
      routeName: 'forms-contracts',
      routePath: '/module/contracts',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'contractors',
      title: 'Contractors',
      subtitle: 'Contractor master and contacts',
      icon: Icons.groups_rounded,
      routeName: 'forms-contractors',
      routePath: '/module/contractors',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'p6',
      title: 'Execution & P6',
      subtitle: 'Activities, actuals and P6 updates',
      icon: Icons.timeline_rounded,
      routeName: 'forms-p6',
      routePath: '/module/p6',
      group: ModuleGroup.updateForms,
    ),
    AppModule(
      id: 'quality',
      title: 'Quality inspections',
      subtitle: 'Inspection records and NCR',
      icon: Icons.verified_rounded,
      routeName: 'forms-quality',
      routePath: '/module/quality',
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
      id: 'documents',
      title: 'Documents',
      subtitle: 'Repository, drafts and files',
      icon: Icons.folder_rounded,
      routeName: 'more-documents',
      routePath: '/module/documents',
      group: ModuleGroup.more,
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
