import 'package:flutter/material.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/officer/models/parolee_summary.dart';

class AssignParoleeDialog extends StatefulWidget {
  const AssignParoleeDialog({
    super.key,
    required this.parolees,
    required this.activity,
  });

  final List<ParoleeSummary> parolees;
  final ActivityModel activity;

  @override
  State<AssignParoleeDialog> createState() => _AssignParoleeDialogState();
}

class _AssignParoleeDialogState extends State<AssignParoleeDialog> {
  late final Set<String> _selected = Set<String>.from(widget.activity.assignedParoleeIds);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Parolees'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.parolees.isEmpty
            ? const Text('No parolees available.')
            : ListView(
                shrinkWrap: true,
                children: widget.parolees
                    .map(
                      (p) => CheckboxListTile(
                        value: _selected.contains(p.id),
                        title: Text(p.fullName),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(p.id);
                            } else {
                              _selected.remove(p.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
