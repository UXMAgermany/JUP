import 'package:flutter/material.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/widgets/date_picker_field.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

/// Step 3 des Event-Create-Wizards. Folgt eigenem Figma-Design
/// (Node 61311:66961): Ort als TextField, Datum + Uhrzeit als Picker-
/// gestützte InputDecorator, Wiederholung & Ablaufdatum als Switches mit
/// conditional reveal.
class EventCreateStep3Schedule extends StatefulWidget {
  final EventCreateFormState state;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickStartTime;
  final ValueChanged<bool> onToggleRepeats;
  final ValueChanged<EventRepeatType> onRepeatsChanged;
  final ValueChanged<bool> onToggleExpiresAt;
  final VoidCallback onPickExpiresAt;

  const EventCreateStep3Schedule({
    super.key,
    required this.state,
    required this.onLocationChanged,
    required this.onPickStartDate,
    required this.onPickStartTime,
    required this.onToggleRepeats,
    required this.onRepeatsChanged,
    required this.onToggleExpiresAt,
    required this.onPickExpiresAt,
  });

  @override
  State<EventCreateStep3Schedule> createState() =>
      _EventCreateStep3ScheduleState();
}

class _EventCreateStep3ScheduleState extends State<EventCreateStep3Schedule> {
  late final TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.state.location);
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gib an, wo und wann das Event stattfindet.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Ort (Pflichtfeld)',
              hintText: 'z.B. JUZ',
            ),
            onChanged: widget.onLocationChanged,
          ),
          const SizedBox(height: 12),
          DatePickerField(
            label: 'Datum',
            value: state.startDate,
            onTap: widget.onPickStartDate,
          ),
          const SizedBox(height: 12),
          _TimePickerField(
            label: 'Uhrzeit',
            value: state.startTime,
            onTap: widget.onPickStartTime,
          ),
          const SizedBox(height: 24),
          _SwitchRow(
            label: 'Soll sich das Event wiederholen?',
            value: state.repeatsEnabled,
            onChanged: widget.onToggleRepeats,
          ),
          if (state.repeatsEnabled) ...[
            const SizedBox(height: 16),
            Text(
              'Wie oft soll sich das Event wiederholen?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceEvenly,
              runAlignment: WrapAlignment.spaceEvenly,
              children: EventRepeatType.values.map((r) {
                return ToggleButton(
                  label: r.displayLabel,
                  selected: state.repeats == r,
                  onTap: () => widget.onRepeatsChanged(r),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          _SwitchRow(
            label: 'Hat das Event ein Ablaufdatum?',
            value: state.expiresAtEnabled,
            onChanged: widget.onToggleExpiresAt,
          ),
          if (state.expiresAtEnabled) ...[
            const SizedBox(height: 12),
            DatePickerField(
              label: 'Ablaufdatum',
              value: state.expiresAt,
              onTap: widget.onPickExpiresAt,
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  String _format(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = value;
    return Semantics(
      label: t == null
          ? '$label auswählen'
          : '$label: ${_format(t)} Uhr, antippen zum Ändern',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          isEmpty: t == null,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.schedule_outlined),
          ),
          child: Text(t == null ? '' : _format(t)),
        ),
      ),
    );
  }
}
