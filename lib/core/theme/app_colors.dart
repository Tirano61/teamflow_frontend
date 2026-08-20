import 'package:flutter/material.dart';

/// Central color tokens for Develop Workflow.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0F1419);
  static const Color backgroundSecondary = Color(0xFF151B22);

  static const Color surface = Color(0xFF1B232C);
  static const Color surfaceElevated = Color(0xFF222C36);
  static const Color surfaceHover = Color(0xFF263340);

  static const Color border = Color(0xFF2C3742);
  static const Color divider = Color(0xFF2C3742);

  static const Color textPrimary = Color(0xFFF3F6F8);
  static const Color textSecondary = Color(0xFFA7B0BA);
  static const Color textMuted = Color(0xFF6F7A86);
  static const Color textDisabled = Color(0xFF5C6671);

  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryHover = Color(0xFF3D7BFF);
  static const Color primaryMuted = Color(0xFF1C355E);

  static const Color error = Color(0xFFD65A62);
  static const Color success = Color(0xFF3FA37C);
  static const Color warning = Color(0xFFD2A94E);
  static const Color info = Color(0xFF4D7DE8);

  static const Color discussionError = Color(0xFFD65A62);
  static const Color discussionIdea = Color(0xFF7A6FF0);
  static const Color discussionImprovement = Color(0xFF42A98B);
  static const Color discussionQuestion = Color(0xFFD2A94E);

  static const Color statusNew = Color(0xFF697684);
  static const Color statusReview = Color(0xFFC89B3C);
  static const Color statusInProgress = Color(0xFF4D7DE8);
  static const Color statusResolved = Color(0xFF3FA37C);

  static const Color unread = Color(0xFF4D8DFF);
}

/// Semantic tokens that should be used as accents in chips/icons/indicators.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.discussionError,
    required this.discussionIdea,
    required this.discussionImprovement,
    required this.discussionQuestion,
    required this.statusNew,
    required this.statusReview,
    required this.statusInProgress,
    required this.statusResolved,
    required this.unread,
  });

  final Color discussionError;
  final Color discussionIdea;
  final Color discussionImprovement;
  final Color discussionQuestion;

  final Color statusNew;
  final Color statusReview;
  final Color statusInProgress;
  final Color statusResolved;

  final Color unread;

  static const AppSemanticColors dark = AppSemanticColors(
    discussionError: AppColors.discussionError,
    discussionIdea: AppColors.discussionIdea,
    discussionImprovement: AppColors.discussionImprovement,
    discussionQuestion: AppColors.discussionQuestion,
    statusNew: AppColors.statusNew,
    statusReview: AppColors.statusReview,
    statusInProgress: AppColors.statusInProgress,
    statusResolved: AppColors.statusResolved,
    unread: AppColors.unread,
  );

  @override
  AppSemanticColors copyWith({
    Color? discussionError,
    Color? discussionIdea,
    Color? discussionImprovement,
    Color? discussionQuestion,
    Color? statusNew,
    Color? statusReview,
    Color? statusInProgress,
    Color? statusResolved,
    Color? unread,
  }) {
    return AppSemanticColors(
      discussionError: discussionError ?? this.discussionError,
      discussionIdea: discussionIdea ?? this.discussionIdea,
      discussionImprovement: discussionImprovement ?? this.discussionImprovement,
      discussionQuestion: discussionQuestion ?? this.discussionQuestion,
      statusNew: statusNew ?? this.statusNew,
      statusReview: statusReview ?? this.statusReview,
      statusInProgress: statusInProgress ?? this.statusInProgress,
      statusResolved: statusResolved ?? this.statusResolved,
      unread: unread ?? this.unread,
    );
  }

  @override
  ThemeExtension<AppSemanticColors> lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) {
      return this;
    }

    return AppSemanticColors(
      discussionError: Color.lerp(discussionError, other.discussionError, t)!,
      discussionIdea: Color.lerp(discussionIdea, other.discussionIdea, t)!,
      discussionImprovement:
          Color.lerp(discussionImprovement, other.discussionImprovement, t)!,
      discussionQuestion:
          Color.lerp(discussionQuestion, other.discussionQuestion, t)!,
      statusNew: Color.lerp(statusNew, other.statusNew, t)!,
      statusReview: Color.lerp(statusReview, other.statusReview, t)!,
      statusInProgress: Color.lerp(statusInProgress, other.statusInProgress, t)!,
      statusResolved: Color.lerp(statusResolved, other.statusResolved, t)!,
      unread: Color.lerp(unread, other.unread, t)!,
    );
  }
}

extension AppSemanticColorsBuildContextX on BuildContext {
  AppSemanticColors get semanticColors {
    return Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
  }
}