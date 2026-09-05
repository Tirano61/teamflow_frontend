import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/discussion_bloc.dart';
import '../../../bloc/discussion_state.dart';

class DiscussionAssignableDevelopersList extends StatelessWidget {
  const DiscussionAssignableDevelopersList({
    required this.selectedIds,
    required this.setDialogState,
    super.key,
  });

  final Set<String> selectedIds;
  final void Function(VoidCallback fn) setDialogState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscussionBloc, DiscussionState>(
      builder: (context, state) {
        if (state.isLoadingAssignableDevelopers &&
            state.assignableDevelopers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.assignableDevelopers.isEmpty) {
          return const Text('No hay developers disponibles.');
        }

        return ListView(
          shrinkWrap: true,
          children: state.assignableDevelopers
              .map(
                (developer) => CheckboxListTile(
                  dense: true,
                  value: selectedIds.contains(developer.id),
                  title: Text(developer.fullName),
                  subtitle:
                      developer.email == null ? null : Text(developer.email!),
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selectedIds.add(developer.id);
                      } else {
                        selectedIds.remove(developer.id);
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
