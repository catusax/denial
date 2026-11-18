part of 'desktop_system_bar.dart';

class _SystemBarCalendarPanel extends StatefulWidget {
  const _SystemBarCalendarPanel({required this.now, required this.onClose});

  static const Size preferredSize = Size(360, 504);

  final DateTime now;
  final VoidCallback onClose;

  @override
  State<_SystemBarCalendarPanel> createState() =>
      _SystemBarCalendarPanelState();
}

class _SystemBarCalendarPanelState extends State<_SystemBarCalendarPanel> {
  late DateTime _selectedDate = DateUtils.dateOnly(widget.now);
  late DateTime _displayedMonth = _selectedDate;
  late List<({DateTime date, CalendarHoliday holiday})> _monthHolidays =
      _holidaysForMonth(_displayedMonth);
  int _pickerResetGeneration = 0;

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = DateUtils.dateOnly(date));
  }

  void _jumpToDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateDisplayedMonth(date);
      _pickerResetGeneration++;
    });
  }

  void _updateDisplayedMonth(DateTime month) {
    if (DateUtils.isSameMonth(_displayedMonth, month)) return;
    _displayedMonth = month;
    _monthHolidays = _holidaysForMonth(month);
  }

  static List<({DateTime date, CalendarHoliday holiday})> _holidaysForMonth(
    DateTime month,
  ) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final entries = <({DateTime date, CalendarHoliday holiday})>[];
    for (var day = 1; day <= days; day++) {
      final date = DateTime(month.year, month.month, day);
      final holiday = chinesePublicHoliday(date);
      if (holiday != null) entries.add((date: date, holiday: holiday));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final materialTheme = context.shellTheme.toMaterialTheme();
    final currentDate = DateUtils.dateOnly(widget.now);
    final datePickerTheme = materialTheme.datePickerTheme;
    final defaultCalendarTextStyle = materialTheme.useMaterial3
        ? materialTheme.textTheme.bodyLarge
        : materialTheme.textTheme.bodySmall;
    final todayButtonTextStyle = materialTheme.textTheme.labelLarge?.copyWith(
      fontSize: 12,
    );
    final todayButtonStyle =
        materialTheme.textButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(todayButtonTextStyle),
        ) ??
        ButtonStyle(textStyle: WidgetStatePropertyAll(todayButtonTextStyle));
    final calendarTheme = materialTheme.copyWith(
      datePickerTheme: datePickerTheme.copyWith(
        dayStyle: (datePickerTheme.dayStyle ?? defaultCalendarTextStyle)
            ?.copyWith(fontSize: 13),
        weekdayStyle: (datePickerTheme.weekdayStyle ?? defaultCalendarTextStyle)
            ?.copyWith(fontSize: 11),
        yearStyle:
            (datePickerTheme.yearStyle ?? materialTheme.textTheme.bodyLarge)
                ?.copyWith(fontSize: 13),
        headerHeadlineStyle:
            (datePickerTheme.headerHeadlineStyle ??
                    (materialTheme.useMaterial3
                        ? materialTheme.textTheme.headlineLarge
                        : materialTheme.textTheme.headlineSmall))
                ?.copyWith(fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(style: todayButtonStyle),
    );

    return Theme(
      data: calendarTheme,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: _SystemBarCalendarPanel.preferredSize.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  top: 8,
                  end: 4,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.formatMediumDate(_selectedDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: materialTheme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _jumpToDate(currentDate),
                      child: Text(localizations.currentDateLabel),
                    ),
                    IconButton(
                      tooltip: localizations.closeButtonTooltip,
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              _SystemBarCalendarPicker(
                key: ValueKey<int>(_pickerResetGeneration),
                selectedDate: _selectedDate,
                currentDate: currentDate,
                onDateChanged: _selectDate,
                onDisplayedMonthChanged: (month) =>
                    setState(() => _updateDisplayedMonth(month)),
              ),
              _buildHolidayAgenda(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolidayAgenda(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final theme = context.shellTheme.toMaterialTheme();
    final colors = theme.colorScheme;
    final tileShape = RoundedRectangleBorder(
      borderRadius: context.shellTheme.borderRadius(8),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 4),
            child: Semantics(
              header: true,
              child: Text(
                chinese ? '中国大陆放假及调休' : 'Mainland China holiday schedule',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
          if (_monthHolidays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                chinese ? '本月无已收录安排' : 'No listed dates this month',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final (:date, :holiday) in _monthHolidays)
            ListTile(
              key: ValueKey(date),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              selected: DateUtils.isSameDay(_selectedDate, date),
              selectedColor: colors.onSecondaryContainer,
              selectedTileColor: colors.secondaryContainer,
              shape: tileShape,
              onTap: () => _jumpToDate(date),
              title: Text(
                '${localizations.formatShortMonthDay(date)} · '
                '${holiday.label(chinese: chinese)}',
              ),
            ),
        ],
      ),
    );
  }
}
