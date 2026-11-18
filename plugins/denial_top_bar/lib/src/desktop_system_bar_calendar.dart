part of 'desktop_system_bar.dart';

const systemBarDateButtonKey = ValueKey<String>('system-bar-date-button');

class _SystemBarClockOwner extends ConsumerStatefulWidget {
  const _SystemBarClockOwner({
    required this.accent,
    required this.monitorId,
    required this.side,
    required this.onOpenDashboard,
  });

  final WallpaperAccent accent;
  final int monitorId;
  final PanelEdge side;
  final VoidCallback onOpenDashboard;

  @override
  ConsumerState<_SystemBarClockOwner> createState() =>
      _SystemBarClockOwnerState();
}

class _SystemBarClockOwnerState extends ConsumerState<_SystemBarClockOwner>
    with SingleTickerProviderStateMixin {
  static const double _popupGap = 9;

  final OverlayPortalController _portal = OverlayPortalController();
  final Object _tapRegionGroup = Object();
  final FocusNode _dateFocusNode = FocusNode(debugLabel: 'System bar date');
  final FocusScopeNode _popupFocusNode = FocusScopeNode(
    debugLabel: 'System bar calendar',
  );
  late final AnimationController _popupMotion;
  late final CurvedAnimation _popupCurve;
  StreamSubscription<DenialShellActionEvent>? _shellActions;
  var _hovered = false;
  var _dateFocused = false;
  var _timeFocused = false;
  var _hideScheduled = false;
  var _calendarOpen = false;
  var _popupEpoch = 0;
  Rect? _popupMonitorBounds;

  bool get _focused => _dateFocused || _timeFocused;

  @override
  void initState() {
    super.initState();
    _popupMotion = AnimationController(
      vsync: this,
      duration: Motion.cardSettle,
      reverseDuration: Motion.tile,
    )..addStatusListener(_handlePopupStatus);
    _popupCurve = CurvedAnimation(
      parent: _popupMotion,
      curve: Motion.md3EmphasizedDecelerate,
      reverseCurve: Motion.md3EmphasizedAccelerate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _popupMotion
      ..duration = reduceMotion ? Duration.zero : Motion.cardSettle
      ..reverseDuration = reduceMotion ? Duration.zero : Motion.tile;
    if (reduceMotion && _popupMotion.isAnimating) {
      if (_calendarOpen) {
        _popupMotion.value = 1;
      } else {
        _scheduleDismiss();
      }
    }
  }

  void _handlePopupStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        !_calendarOpen &&
        _portal.isShowing) {
      _portal.hide();
    }
  }

  @override
  void didUpdateWidget(covariant _SystemBarClockOwner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monitorId != widget.monitorId ||
        oldWidget.side != widget.side) {
      _scheduleDismiss();
    }
  }

  @override
  void dispose() {
    _stopNativePressObservation();
    _popupCurve.dispose();
    _popupMotion.dispose();
    _popupFocusNode.dispose();
    _dateFocusNode.dispose();
    super.dispose();
  }

  void _startNativePressObservation() {
    _shellActions ??= ref.read(denialBridgeProvider).shellActions.listen((
      event,
    ) {
      if (event.action == DenialShellAction.clientPointerPressed) {
        _dismiss(restoreFocus: false);
      }
    });
  }

  void _stopNativePressObservation() {
    final shellActions = _shellActions;
    _shellActions = null;
    if (shellActions != null) unawaited(shellActions.cancel());
  }

  void _openDashboard() {
    _dismiss(restoreFocus: false);
    widget.onOpenDashboard();
  }

  void _toggleCalendar() {
    if (_calendarOpen) {
      _dismiss(restoreFocus: true);
      return;
    }
    final monitorBounds = ref.read(
      context.workspaceServices.monitorBounds(widget.monitorId),
    );
    if (!ShellSurfacePresentation.visibleOf(context) ||
        widget.side == PanelEdge.hidden ||
        monitorBounds == null) {
      return;
    }
    _popupEpoch++;
    _hideScheduled = false;
    _popupMonitorBounds = monitorBounds;
    setState(() => _calendarOpen = true);
    _startNativePressObservation();
    if (!_portal.isShowing) _portal.show();
    _popupFocusNode
      ..canRequestFocus = true
      ..requestFocus();
    _popupMotion.forward();
  }

  void _dismiss({required bool restoreFocus}) {
    if (!_calendarOpen) return;
    setState(() => _calendarOpen = false);
    _stopNativePressObservation();
    _popupFocusNode.unfocus();
    _popupFocusNode.canRequestFocus = false;
    // Restore only for the initiating close; never from animation completion.
    if (restoreFocus) _dateFocusNode.requestFocus();
    if (_popupMotion.isDismissed) {
      _portal.hide();
    } else {
      _popupMotion.reverse();
    }
  }

  void _scheduleDismiss() {
    if (_hideScheduled) return;
    _hideScheduled = true;
    _calendarOpen = false;
    _stopNativePressObservation();
    _popupMotion.stop();
    final epoch = ++_popupEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _popupEpoch) return;
      _hideScheduled = false;
      _popupFocusNode.unfocus();
      if (_portal.isShowing) _portal.hide();
      _popupMotion.reset();
    });
  }

  Widget _animatePopup(Widget child) {
    final (axis, alignment) = switch (widget.side) {
      PanelEdge.top => (Axis.vertical, Alignment.topCenter),
      PanelEdge.bottom => (Axis.vertical, Alignment.bottomCenter),
      PanelEdge.left => (Axis.horizontal, Alignment.centerLeft),
      PanelEdge.right ||
      PanelEdge.hidden => (Axis.horizontal, Alignment.centerRight),
    };
    // Loosen Positioned's tight constraints so only the revealed bounds capture
    // input. The calendar keeps its full layout behind SizeTransition's clip.
    return Align(
      alignment: alignment,
      child: ShellInputRegion(
        debugLabel: 'System bar calendar popup',
        active: _calendarOpen,
        keyboardPolicy: _calendarOpen
            ? ShellKeyboardPolicy.capture
            : ShellKeyboardPolicy.none,
        observeClientPointerPresses: _calendarOpen,
        child: FadeTransition(
          opacity: _popupCurve,
          child: SizeTransition(
            sizeFactor: _popupCurve,
            axis: axis,
            alignment: alignment,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildPopup(
    BuildContext context,
    OverlayChildLayoutInfo layout,
    DateTime now,
    Rect? monitorBounds,
    bool visible,
  ) {
    if (_hideScheduled ||
        !visible ||
        widget.side == PanelEdge.hidden ||
        monitorBounds == null) {
      _scheduleDismiss();
      return const SizedBox.shrink();
    }
    final determinant = layout.childPaintTransform.determinant();
    if (!determinant.isFinite || determinant == 0 || layout.childSize.isEmpty) {
      _scheduleDismiss();
      return const SizedBox.shrink();
    }

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) {
      _scheduleDismiss();
      return const SizedBox.shrink();
    }
    final monitorRect = Rect.fromPoints(
      overlay.globalToLocal(monitorBounds.topLeft),
      overlay.globalToLocal(monitorBounds.bottomRight),
    );
    final overlayRect = Offset.zero & layout.overlaySize;
    final safeRect = monitorRect.intersect(overlayRect);
    if (!monitorRect.isFinite || !overlayRect.isFinite || safeRect.isEmpty) {
      _scheduleDismiss();
      return const SizedBox.shrink();
    }

    final anchor = MatrixUtils.transformRect(
      layout.childPaintTransform,
      Offset.zero & layout.childSize,
    );
    if (!anchor.isFinite || anchor.isEmpty) {
      _scheduleDismiss();
      return const SizedBox.shrink();
    }
    final popupSize = Size(
      math.min(_SystemBarCalendarPanel.preferredSize.width, safeRect.width),
      math.min(_SystemBarCalendarPanel.preferredSize.height, safeRect.height),
    );
    late final Offset preferredOrigin;
    switch (widget.side) {
      case PanelEdge.top:
        preferredOrigin = Offset(
          anchor.center.dx - popupSize.width / 2,
          anchor.bottom + _popupGap,
        );
      case PanelEdge.bottom:
        preferredOrigin = Offset(
          anchor.center.dx - popupSize.width / 2,
          anchor.top - popupSize.height - _popupGap,
        );
      case PanelEdge.left:
        preferredOrigin = Offset(
          anchor.right + _popupGap,
          anchor.center.dy - popupSize.height / 2,
        );
      case PanelEdge.right:
      case PanelEdge.hidden:
        preferredOrigin = Offset(
          anchor.left - popupSize.width - _popupGap,
          anchor.center.dy - popupSize.height / 2,
        );
    }
    final origin = Offset(
      preferredOrigin.dx
          .clamp(safeRect.left, safeRect.right - popupSize.width)
          .toDouble(),
      preferredOrigin.dy
          .clamp(safeRect.top, safeRect.bottom - popupSize.height)
          .toDouble(),
    );
    final panel = SizedBox(
      width: _SystemBarCalendarPanel.preferredSize.width,
      height: popupSize.height,
      child: SingleChildScrollView(
        child: _SystemBarCalendarPanel(
          now: now,
          onClose: () => _dismiss(restoreFocus: true),
        ),
      ),
    );
    final content =
        popupSize.width < _SystemBarCalendarPanel.preferredSize.width
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: panel)
        : panel;
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: popupSize.width,
      height: popupSize.height,
      child: _animatePopup(
        IgnorePointer(
          ignoring: !_calendarOpen,
          child: ExcludeSemantics(
            excluding: !_calendarOpen,
            child: TapRegion(
              groupId: _tapRegionGroup,
              enabled: _calendarOpen,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      _dismiss(restoreFocus: true),
                },
                child: FocusScope(
                  node: _popupFocusNode,
                  autofocus: _calendarOpen,
                  canRequestFocus: _calendarOpen,
                  descendantsAreFocusable: _calendarOpen,
                  descendantsAreTraversable: _calendarOpen,
                  child: FocusTraversalGroup(
                    child: ShellBackdropBlur(
                      blur: ShellTheme.of(context).effectiveCardOpacity < 1.0,
                      borderRadius: ShellTheme.of(context).borderRadius(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ShellTheme.of(
                            context,
                          ).cardColor(context.shellColors.surfaceContainerLow),
                          borderRadius: ShellTheme.of(context).borderRadius(24),
                          border: Border.all(
                            color: context.shellTheme.accent.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now =
        ref.watch(context.telemetryServices.clock).value ?? DateTime.now();
    final monitorBounds = ref.watch(
      context.workspaceServices.monitorBounds(widget.monitorId),
    );
    final visible = ShellSurfacePresentation.visibleOf(context);
    if ((!visible ||
            monitorBounds == null ||
            (_portal.isShowing && monitorBounds != _popupMonitorBounds) ||
            widget.side == PanelEdge.hidden) &&
        _portal.isShowing) {
      _scheduleDismiss();
    }
    final date = context.pluginStrings.shortDate(now);
    final time = context.pluginStrings.time(now);
    final datePickerHelp = MaterialLocalizations.of(context).datePickerHelpText;

    final dateButton = TapRegion(
      groupId: _tapRegionGroup,
      consumeOutsideTaps: false,
      onTapOutside: (_) => _dismiss(restoreFocus: false),
      child: Semantics(
        button: true,
        label: date,
        hint: datePickerHelp,
        onTap: _toggleCalendar,
        child: ExcludeSemantics(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: systemBarDateButtonKey,
              focusNode: _dateFocusNode,
              borderRadius: context.shellTheme.borderRadius(999),
              mouseCursor: context.presentationServices.linkCursor,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(
                ShellMediaColors.transparentDark,
              ),
              onTap: _toggleCalendar,
              onFocusChange: (value) => setState(() {
                _dateFocused = value;
              }),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
                child: Center(
                  widthFactor: 1,
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.wallpaperReveal,
                    curve: Motion.standard,
                    style: ShellText.systemBarCaption.copyWith(
                      color: widget.accent.captionColor(context.shellTheme),
                    ),
                    child: Text(date),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final timeButton = Semantics(
      button: true,
      label: context.pluginStrings.openDashboard,
      value: time,
      onTap: _openDashboard,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: systemBarClockButtonKey,
            borderRadius: context.shellTheme.borderRadius(999),
            mouseCursor: context.presentationServices.linkCursor,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(
              ShellMediaColors.transparentDark,
            ),
            onTap: _openDashboard,
            onFocusChange: (value) => setState(() {
              _timeFocused = value;
            }),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, end: 12),
              child: Center(
                widthFactor: 1,
                child: AnimatedSwitcher(
                  duration: Motion.cardSettle,
                  switchInCurve: Motion.standard,
                  switchOutCurve: Motion.standard,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    time,
                    key: ValueKey<String>(time),
                    style: ShellText.systemBarValue,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.side.isHorizontal
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [dateButton, timeButton],
    );

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, layout) =>
          _buildPopup(context, layout, now, monitorBounds, visible),
      child: _SystemBarCard(
        accent: widget.accent,
        padding: EdgeInsets.zero,
        highlighted: _hovered || _focused,
        focused: _focused,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: actions,
        ),
      ),
    );
  }
}
