import 'package:flutter/material.dart';

import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'saving_goals_create.dart';

/// Backward-compatible route class for editing a Saving Goal.
class UpdateGoalScreen extends StatelessWidget {
  const UpdateGoalScreen({super.key, required this.goal});

  final FinanceSavingGoalEntity goal;

  @override
  Widget build(BuildContext context) => CreateGoalScreen(goal: goal);
}
