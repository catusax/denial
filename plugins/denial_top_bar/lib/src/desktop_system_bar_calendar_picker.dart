part of 'desktop_system_bar.dart';

const _calendar = GregorianCalendarDelegate();

/// The month grid owns day contents so it can mark dates while keeping the
/// stock Material year picker and Gregorian calendar calculations.
class _SystemBarCalendarPicker extends StatefulWidget {
  const _SystemBarCalendarPicker({
    super.key,
    required this.selectedDate,
    required this.currentDate,
    required this.onDateChanged,
    required this.onDisplayedMonthChanged,
  });

  final DateTime selectedDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime> onDisplayedMonthChanged;

  @override
  State<_SystemBarCalendarPicker> createState() =>
      _SystemBarCalendarPickerState();
}

class _SystemBarCalendarPickerState extends State<_SystemBarCalendarPicker> {
  static final _firstDate = DateTime(1);
  static final _lastDate = DateTime(9999, 12, 31);
  static const _monthTransition = Duration(milliseconds: 200);
  static final _monthCount = _calendar.monthDelta(_firstDate, _lastDate) + 1;

  late DateTime _month = _monthOf(widget.selectedDate);
  late PageController _pages = _controllerForMonth();
  final _gridFocus = FocusNode(debugLabel: 'Calendar day grid');
  DateTime? _focusedDate;
  bool _selectingYear = false;

  static DateTime _monthOf(DateTime date) =>
      _calendar.getMonth(date.year, date.month);

  PageController _controllerForMonth() => PageController(
    initialPage: _calendar.monthDelta(_firstDate, _month),
    keepPage: false,
  );

  @override
  void dispose() {
    _pages.dispose();
    _gridFocus.dispose();
    super.dispose();
  }

  void _updateMonth(DateTime date) {
    final month = _monthOf(date);
    if (month == _month) return;
    _month = month;
    widget.onDisplayedMonthChanged(month);
  }

  void _handlePageChanged(int index) {
    final month = _calendar.addMonthsToMonthDate(_firstDate, index);
    if (month == _month) return;
    setState(() {
      _updateMonth(month);
      final focused = _focusedDate;
      if (focused != null && !DateUtils.isSameMonth(focused, month)) {
        final days = _calendar.getDaysInMonth(month.year, month.month);
        _focusedDate = _calendar.getDay(
          month.year,
          month.month,
          focused.day <= days ? focused.day : 1,
        );
      }
    });
  }

  void _showMonth(DateTime month) {
    _pages.animateToPage(
      _calendar.monthDelta(_firstDate, month),
      duration: _monthTransition,
      curve: Curves.ease,
    );
  }

  void _toggleYears() {
    setState(() {
      _selectingYear = !_selectingYear;
      if (!_selectingYear) _resetMonthGrid();
    });
  }

  void _resetMonthGrid() {
    _pages.dispose();
    _pages = _controllerForMonth();
    _focusedDate = null;
  }

  void _selectYear(DateTime date) {
    final day = math.min(
      widget.selectedDate.day,
      _calendar.getDaysInMonth(date.year, date.month),
    );
    final selected = _calendar.getDay(date.year, date.month, day);
    setState(() {
      _selectingYear = false;
      _updateMonth(selected);
      _resetMonthGrid();
    });
    widget.onDateChanged(selected);
  }

  void _handleGridFocus(bool focused) {
    if (_selectingYear) return;
    setState(() {
      if (!focused) return;
      _focusedDate ??= DateUtils.isSameMonth(widget.selectedDate, _month)
          ? widget.selectedDate
          : DateUtils.isSameMonth(widget.currentDate, _month)
          ? widget.currentDate
          : _month;
    });
  }

  void _moveFocus(TraversalDirection direction) {
    final focused = _focusedDate;
    if (focused == null) return;
    final forward = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final offset = switch (direction) {
      TraversalDirection.left => -forward,
      TraversalDirection.right => forward,
      TraversalDirection.up => -DateTime.daysPerWeek,
      TraversalDirection.down => DateTime.daysPerWeek,
    };
    final target = _calendar.addDaysToDate(focused, offset);
    if (target.isBefore(_firstDate) || target.isAfter(_lastDate)) return;
    final crossesMonth = !DateUtils.isSameMonth(target, _month);
    setState(() {
      _focusedDate = target;
      if (crossesMonth) _updateMonth(target);
    });
    if (crossesMonth) {
      // Commit the focus and page together so repeated arrows cannot lose it.
      _pages.jumpToPage(_calendar.monthDelta(_firstDate, target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final theme = DatePickerTheme.of(context);
    final defaults = DatePickerTheme.defaults(context);
    final headerColor =
        theme.subHeaderForegroundColor ?? defaults.subHeaderForegroundColor;
    final titleStyle =
        theme.toggleButtonTextStyle ?? defaults.toggleButtonTextStyle;
    final monthIndex = _calendar.monthDelta(_firstDate, _month);
    final portraitMaterial3 =
        Theme.of(context).useMaterial3 &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 3);
    final scale = scaler.scale(14) / 14;
    final rowHeight =
        (portraitMaterial3 ? 48.0 : 42.0) + (scale > 1.3 ? (scale - 1) * 8 : 0);

    final monthTitle = localizations.formatMonthYear(_month);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Semantics(
                    button: true,
                    liveRegion: true,
                    label:
                        '$monthTitle, ${localizations.selectYearSemanticsLabel}',
                    onTap: _toggleYears,
                    child: InkWell(
                      onTap: _toggleYears,
                      excludeFromSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ExcludeSemantics(
                                child: Text(
                                  monthTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle?.apply(
                                    color:
                                        theme.toggleButtonTextStyle?.color ??
                                        headerColor,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _selectingYear ? .5 : 0,
                              duration: _monthTransition,
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_selectingYear) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: headerColor,
                    tooltip: localizations.previousMonthTooltip,
                    onPressed: monthIndex > 0
                        ? () => _showMonth(
                            _calendar.addMonthsToMonthDate(_month, -1),
                          )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: headerColor,
                    tooltip: localizations.nextMonthTooltip,
                    onPressed: monthIndex + 1 < _monthCount
                        ? () => _showMonth(
                            _calendar.addMonthsToMonthDate(_month, 1),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(
          height: 7 * rowHeight,
          child: _selectingYear
              ? YearPicker(
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  currentDate: widget.currentDate,
                  selectedDate: _month,
                  onChanged: _selectYear,
                  calendarDelegate: _calendar,
                )
              : FocusableActionDetector(
                  focusNode: _gridFocus,
                  onFocusChange: _handleGridFocus,
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.arrowLeft):
                        DirectionalFocusIntent(TraversalDirection.left),
                    SingleActivator(LogicalKeyboardKey.arrowRight):
                        DirectionalFocusIntent(TraversalDirection.right),
                    SingleActivator(LogicalKeyboardKey.arrowUp):
                        DirectionalFocusIntent(TraversalDirection.up),
                    SingleActivator(LogicalKeyboardKey.arrowDown):
                        DirectionalFocusIntent(TraversalDirection.down),
                  },
                  actions: <Type, Action<Intent>>{
                    DirectionalFocusIntent:
                        CallbackAction<DirectionalFocusIntent>(
                          onInvoke: (intent) => _moveFocus(intent.direction),
                        ),
                    NextFocusIntent: CallbackAction<NextFocusIntent>(
                      onInvoke: (_) {
                        _gridFocus.requestFocus();
                        return _gridFocus.nextFocus();
                      },
                    ),
                    PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                      onInvoke: (_) {
                        _gridFocus.requestFocus();
                        return _gridFocus.previousFocus();
                      },
                    ),
                  },
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _monthCount,
                    onPageChanged: _handlePageChanged,
                    itemBuilder: (context, index) {
                      final month = _calendar.addMonthsToMonthDate(
                        _firstDate,
                        index,
                      );
                      return _SystemBarCalendarMonth(
                        key: ValueKey(month),
                        month: month,
                        selectedDate: widget.selectedDate,
                        currentDate: widget.currentDate,
                        focusedDate: _gridFocus.hasFocus && month == _month
                            ? _focusedDate
                            : null,
                        rowHeight: rowHeight,
                        insetCells: portraitMaterial3,
                        onSelected: (date) {
                          _focusedDate = date;
                          widget.onDateChanged(date);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SystemBarCalendarMonth extends StatefulWidget {
  const _SystemBarCalendarMonth({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.currentDate,
    required this.focusedDate,
    required this.rowHeight,
    required this.insetCells,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime currentDate;
  final DateTime? focusedDate;
  final double rowHeight;
  final bool insetCells;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_SystemBarCalendarMonth> createState() =>
      _SystemBarCalendarMonthState();
}

class _SystemBarCalendarMonthState extends State<_SystemBarCalendarMonth> {
  int get _year => widget.month.year;
  int get _month => widget.month.month;

  late final _dayCount = _calendar.getDaysInMonth(_year, _month);
  late final _dayFocus = List.generate(
    _dayCount,
    (day) =>
        FocusNode(skipTraversal: true, debugLabel: 'Calendar day ${day + 1}'),
  );

  @override
  void initState() {
    super.initState();
    _focusDate();
  }

  @override
  void didUpdateWidget(_SystemBarCalendarMonth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(widget.focusedDate, oldWidget.focusedDate)) {
      _focusDate();
    }
  }

  void _focusDate() {
    final date = widget.focusedDate;
    if (date != null && DateUtils.isSameMonth(date, widget.month)) {
      _dayFocus[date.day - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final node in _dayFocus) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final firstWeekday = localizations.firstDayOfWeekIndex;
    final offset = _calendar.firstDayOffset(_year, _month, localizations);
    final theme = DatePickerTheme.of(context);
    final defaults = DatePickerTheme.defaults(context);
    final weekdayStyle = theme.weekdayStyle ?? defaults.weekdayStyle;
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final colors = Theme.of(context).colorScheme;
    final surface = context.shellColors.surfaceContainerLow;

    return Material(
      type: MaterialType.transparency,
      child: GridView.count(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        crossAxisCount: DateTime.daysPerWeek,
        mainAxisExtent: widget.rowHeight,
        children: [
          for (var i = 0; i < DateTime.daysPerWeek; i++)
            ExcludeSemantics(
              child: Center(
                child: Text(
                  localizations.narrowWeekdays[(firstWeekday + i) %
                      DateTime.daysPerWeek],
                  style: weekdayStyle,
                ),
              ),
            ),
          for (var i = 0; i < offset; i++) const SizedBox.shrink(),
          for (var day = 1; day <= _dayCount; day++)
            _buildDay(
              date: _calendar.getDay(_year, _month, day),
              localizations: localizations,
              theme: theme,
              defaults: defaults,
              chinese: chinese,
              colors: colors,
              surface: surface,
            ),
        ],
      ),
    );
  }

  Widget _buildDay({
    required DateTime date,
    required MaterialLocalizations localizations,
    required DatePickerThemeData theme,
    required DatePickerThemeData defaults,
    required bool chinese,
    required ColorScheme colors,
    required Color surface,
  }) {
    final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
    final isToday = DateUtils.isSameDay(date, widget.currentDate);
    final states = isSelected
        ? const {WidgetState.selected}
        : const <WidgetState>{};
    final foreground = isToday
        ? theme.todayForegroundColor?.resolve(states) ??
              defaults.todayForegroundColor?.resolve(states)
        : theme.dayForegroundColor?.resolve(states) ??
              defaults.dayForegroundColor?.resolve(states);
    final background = isToday
        ? theme.todayBackgroundColor?.resolve(states) ??
              defaults.todayBackgroundColor?.resolve(states)
        : theme.dayBackgroundColor?.resolve(states) ??
              defaults.dayBackgroundColor?.resolve(states);
    final shape =
        theme.dayShape?.resolve(states) ?? defaults.dayShape!.resolve(states)!;
    final todayBorder = theme.todayBorder ?? defaults.todayBorder!;
    final cellShape = isToday
        ? shape.copyWith(
            side: todayBorder.color.a == 0
                ? todayBorder.copyWith(color: foreground)
                : todayBorder,
          )
        : shape;
    final holiday = chinesePublicHoliday(date);
    final numeral = localizations.formatDecimal(date.day);
    final todayLabel = isToday ? ', ${localizations.currentDateLabel}' : '';
    final holidayLabel = holiday == null
        ? ''
        : ', ${holiday.label(chinese: chinese)}';
    Color? marker;
    var textColor = foreground;
    if (holiday != null) {
      final cellBackground = Color.alphaBlend(
        background ?? Colors.transparent,
        surface,
      );
      marker = _markerColor(colors, cellBackground, holiday.isMakeUpWorkday);
      if (!isSelected && !isToday && _contrast(marker, cellBackground) >= 4.5) {
        textColor = marker;
      }
    }

    final content = Ink(
      decoration: ShapeDecoration(color: background, shape: cellShape),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              numeral,
              style: (theme.dayStyle ?? defaults.dayStyle)?.apply(
                color: textColor,
              ),
            ),
            if (marker != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: -5,
                child: Center(
                  child: SizedBox.square(
                    dimension: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: marker,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    void select() => widget.onSelected(date);
    return Semantics(
      container: true,
      label:
          '$numeral, ${localizations.formatFullDate(date)}$todayLabel$holidayLabel',
      button: true,
      selected: isSelected,
      onTap: select,
      child: InkResponse(
        containedInkWell: true,
        focusNode: _dayFocus[date.day - 1],
        onTap: select,
        excludeFromSemantics: true,
        customBorder: shape,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              theme.dayOverlayColor?.resolve(states) ??
              defaults.dayOverlayColor?.resolve(states),
        ),
        child: ExcludeSemantics(
          child: widget.insetCells
              ? Padding(padding: const EdgeInsets.all(4), child: content)
              : content,
        ),
      ),
    );
  }

  static Color _markerColor(ColorScheme colors, Color background, bool makeUp) {
    final base = makeUp ? colors.tertiary : colors.error;
    if (_contrast(base, background) >= 3) return base;
    final container = makeUp ? colors.tertiaryContainer : colors.errorContainer;
    final onContainer = makeUp
        ? colors.onTertiaryContainer
        : colors.onErrorContainer;
    return _contrast(container, background) >=
            _contrast(onContainer, background)
        ? container
        : onContainer;
  }

  static double _contrast(Color foreground, Color background) {
    final first = foreground.computeLuminance();
    final second = background.computeLuminance();
    return (math.max(first, second) + .05) / (math.min(first, second) + .05);
  }
}
