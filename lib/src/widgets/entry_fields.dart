import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Text field with type-ahead suggestions. Suggestions come from
/// [optionsBuilder]; the user can always keep typing a custom value.
class AutocompleteEntry extends StatefulWidget {
  const AutocompleteEntry({
    required this.controller,
    required this.label,
    required this.optionsBuilder,
    this.onChanged,
    this.onSelected,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final List<String> Function(String query) optionsBuilder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;

  @override
  State<AutocompleteEntry> createState() => _AutocompleteEntryState();
}

class DateDropdownEntry extends StatelessWidget {
  const DateDropdownEntry({
    required this.value,
    required this.onChanged,
    this.label = 'Date',
    this.firstYearOffset = -1,
    this.yearCount = 5,
    super.key,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final int firstYearOffset;
  final int yearCount;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      yearCount,
      (index) => currentYear + firstYearOffset + index,
    );
    if (!years.contains(value.year)) years.add(value.year);
    years.sort();
    final daysInMonth = DateUtils.getDaysInMonth(value.year, value.month);
    final day = value.day.clamp(1, daysInMonth);

    DateTime safeDate({int? year, int? month, int? day}) {
      final nextYear = year ?? value.year;
      final nextMonth = month ?? value.month;
      final maxDay = DateUtils.getDaysInMonth(nextYear, nextMonth);
      return DateTime(
        nextYear,
        nextMonth,
        (day ?? value.day).clamp(1, maxDay),
        value.hour,
        value.minute,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'month-${value.year}-${value.month}-${value.day}',
                  ),
                  initialValue: value.month,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: [
                    for (var i = 0; i < _months.length; i++)
                      DropdownMenuItem(value: i + 1, child: Text(_months[i])),
                  ],
                  onChanged: (selected) {
                    if (selected != null) onChanged(safeDate(month: selected));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'day-${value.year}-${value.month}-${value.day}',
                  ),
                  initialValue: day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: [
                    for (var i = 1; i <= daysInMonth; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (selected) {
                    if (selected != null) onChanged(safeDate(day: selected));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey('year-${value.year}-${value.month}-${value.day}'),
            initialValue: value.year,
            decoration: const InputDecoration(labelText: 'Year'),
            items: [
              for (final year in years)
                DropdownMenuItem(value: year, child: Text('$year')),
            ],
            onChanged: (selected) {
              if (selected != null) onChanged(safeDate(year: selected));
            },
          ),
        ],
      ),
    );
  }
}

class TimeDropdownEntry extends StatelessWidget {
  const TimeDropdownEntry({
    required this.value,
    required this.onChanged,
    this.label = 'Time',
    super.key,
  });

  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute;
    final period = value.period;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('hour-${value.hour}-${value.minute}'),
                  initialValue: hour,
                  decoration: const InputDecoration(labelText: 'Hour'),
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (selected) {
                    if (selected == null) return;
                    final nextHour = _to24Hour(selected, period);
                    onChanged(TimeOfDay(hour: nextHour, minute: minute));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('minute-${value.hour}-${value.minute}'),
                  initialValue: minute,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  items: [
                    for (var i = 0; i < 60; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(i.toString().padLeft(2, '0')),
                      ),
                  ],
                  onChanged: (selected) {
                    if (selected == null) return;
                    onChanged(TimeOfDay(hour: value.hour, minute: selected));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<DayPeriod>(
                  key: ValueKey('period-${value.hour}-${value.minute}'),
                  initialValue: period,
                  decoration: const InputDecoration(labelText: 'AM/PM'),
                  items: const [
                    DropdownMenuItem(value: DayPeriod.am, child: Text('AM')),
                    DropdownMenuItem(value: DayPeriod.pm, child: Text('PM')),
                  ],
                  onChanged: (selected) {
                    if (selected == null) return;
                    onChanged(
                      TimeOfDay(
                        hour: _to24Hour(hour, selected),
                        minute: minute,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _to24Hour(int hour, DayPeriod period) {
    final normalized = hour == 12 ? 0 : hour;
    return period == DayPeriod.am ? normalized : normalized + 12;
  }
}

class _AutocompleteEntryState extends State<AutocompleteEntry> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (value) => widget.optionsBuilder(value.text),
        onSelected: widget.onSelected,
        fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: widget.label),
              onChanged: widget.onChanged,
              onSubmitted: (_) => onSubmit(),
            ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220,
                maxWidth: constraints.maxWidth,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dropdown for picking how far in advance a reminder should fire.
/// Value is minutes before the event; -1 means no reminder.
class ReminderDropdown extends StatelessWidget {
  const ReminderDropdown({
    required this.value,
    required this.onChanged,
    required this.choices,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// Map of minutes → label, e.g. {5: '5 minutes before'}.
  final Map<int, String> choices;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Remind me'),
      items: choices.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (selected) => onChanged(selected ?? -1),
    ),
  );
}

/// Dropdown of preset options plus an "Other" choice that reveals a text
/// field for manual entry. The final value is written to [controller].
class DropdownEntry extends StatefulWidget {
  const DropdownEntry({
    required this.controller,
    required this.label,
    required this.options,
    this.otherHint,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final List<String> options;
  final String? otherHint;

  /// Called with the new value when a preset is picked, or '' for "Other".
  final ValueChanged<String>? onChanged;

  @override
  State<DropdownEntry> createState() => _DropdownEntryState();
}

class _DropdownEntryState extends State<DropdownEntry> {
  static const String _other = '__other__';
  String? _selected;

  @override
  void initState() {
    super.initState();
    _syncFromController();
  }

  void _syncFromController() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      _selected = null;
    } else {
      _selected = widget.options.contains(text) ? text : _other;
    }
  }

  @override
  void didUpdateWidget(DropdownEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.options, widget.options) ||
        (_selected != _other &&
            widget.controller.text.trim() != (_selected ?? ''))) {
      // Preserve custom text and reflect externally selected defaults.
      _syncFromController();
    }
  }

  @override
  Widget build(BuildContext context) {
    // No preset options: fall back to a plain text field.
    if (widget.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: widget.controller,
          style: Theme.of(context).textTheme.bodyLarge,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: widget.label),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            // Recreate the field when the option list changes so the
            // displayed selection stays in sync.
            key: ValueKey(
              Object.hash(_selected, Object.hashAll(widget.options)),
            ),
            initialValue: _selected,
            isExpanded: true,
            decoration: InputDecoration(labelText: widget.label),
            items: [
              ...widget.options.map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              ),
              const DropdownMenuItem(
                value: _other,
                child: Text('Other (enter manually)'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selected = value;
                widget.controller.text = (value == null || value == _other)
                    ? ''
                    : value;
              });
              widget.onChanged?.call(widget.controller.text);
            },
          ),
          if (_selected == _other)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextField(
                controller: widget.controller,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText:
                      widget.otherHint ?? 'Enter ${widget.label.toLowerCase()}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
