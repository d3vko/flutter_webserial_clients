import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';
import '../marauder_controller.dart';

class WorkflowDialog extends StatefulWidget {
  const WorkflowDialog({
    required this.workflow,
    required this.onExecute,
    required this.onClose,
    super.key,
  });

  final MarauderWorkflow workflow;
  final void Function(List<WorkflowStepInput> inputs) onExecute;
  final VoidCallback onClose;

  @override
  State<WorkflowDialog> createState() => _WorkflowDialogState();
}

class _WorkflowDialogState extends State<WorkflowDialog> {
  late final List<TextEditingController> _primaryControllers;
  late final List<TextEditingController> _secondaryControllers;
  late final List<TextEditingController> _payloadControllers;

  @override
  void initState() {
    super.initState();
    _primaryControllers = List.generate(
      widget.workflow.steps.length,
      (_) => TextEditingController(),
    );
    _secondaryControllers = List.generate(
      widget.workflow.steps.length,
      (_) => TextEditingController(),
    );
    _payloadControllers = List.generate(
      widget.workflow.steps.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _primaryControllers) {
      c.dispose();
    }
    for (final c in _secondaryControllers) {
      c.dispose();
    }
    for (final c in _payloadControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _execute() {
    final inputs = <WorkflowStepInput>[];
    for (var i = 0; i < widget.workflow.steps.length; i++) {
      final step = widget.workflow.steps[i];
      inputs.add(
        WorkflowStepInput(
          primary: step.requiresInput
              ? _primaryControllers[i].text.trim()
              : null,
          secondary: step.requiresSecondInput
              ? _secondaryControllers[i].text.trim()
              : null,
          serialPayload: step.requiresSerialPayload
              ? _payloadControllers[i].text
              : null,
        ),
      );
    }
    widget.onExecute(inputs);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.workflow.name),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.workflow.description),
              const SizedBox(height: 16),
              for (var i = 0; i < widget.workflow.steps.length; i++) ...[
                _StepTile(
                  index: i + 1,
                  step: widget.workflow.steps[i],
                  primaryController: _primaryControllers[i],
                  secondaryController: _secondaryControllers[i],
                  payloadController: _payloadControllers[i],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        FilledButton(onPressed: _execute, child: const Text('Execute')),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.primaryController,
    required this.secondaryController,
    required this.payloadController,
  });

  final int index;
  final WorkflowStep step;
  final TextEditingController primaryController;
  final TextEditingController secondaryController;
  final TextEditingController payloadController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step $index', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              step.description.isNotEmpty ? step.description : step.command,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            if (step.requiresInput) ...[
              const SizedBox(height: 8),
              TextField(
                controller: primaryController,
                decoration: InputDecoration(
                  labelText: step.inputLabel.isNotEmpty
                      ? step.inputLabel
                      : 'Input',
                  hintText: step.placeholder,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (step.requiresSecondInput) ...[
              const SizedBox(height: 8),
              TextField(
                controller: secondaryController,
                decoration: InputDecoration(
                  labelText: step.secondInputLabel.isNotEmpty
                      ? step.secondInputLabel
                      : 'Second input',
                  hintText: step.secondPlaceholder,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (step.requiresSerialPayload) ...[
              const SizedBox(height: 8),
              TextField(
                controller: payloadController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: step.serialPayloadLabel.isNotEmpty
                      ? step.serialPayloadLabel
                      : 'Serial payload',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showWorkflowDialog(
  BuildContext context, {
  required MarauderWorkflow workflow,
  required void Function(List<WorkflowStepInput> inputs) onExecute,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => WorkflowDialog(
      workflow: workflow,
      onExecute: onExecute,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}
