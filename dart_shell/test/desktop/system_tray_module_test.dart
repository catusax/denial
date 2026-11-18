import 'package:denial_desktop/src/desktop/system_tray_module.dart';
import 'package:denial_flutter_sdk/models.dart';
import 'package:denial_flutter_sdk/theme.dart';
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kMiddleMouseButton, kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SystemTrayItem _item(SystemTrayItemSource source, {bool tooltip = true}) =>
    SystemTrayItem(
      id: 'test-tray',
      source: source,
      title: 'Application status',
      status: SystemTrayStatus.needsAttention,
      iconName: '',
      iconThemePath: '',
      iconPixmap: null,
      menuAvailable: true,
      primaryOpensMenu: false,
      tooltipTitle: tooltip ? 'Tooltip title' : '',
      tooltipDescription: tooltip ? '<b>Activity</b> &amp; details' : '',
    );

Widget _host({
  required SystemTrayItem item,
  bool horizontal = true,
  SystemTrayInvoke? onInvoke,
  SystemTrayMenuInvoke? onInvokeMenu,
}) => ProviderScope(
  child: ShellTheme(
    data: const ShellThemeData(transparencyMode: ShellTransparencyMode.off),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SystemTrayModule(
            horizontal: horizontal,
            accent: Colors.blue,
            items: [item],
            onInvoke: onInvoke ?? (_, _, _) => true,
            onLoadMenu: (_) async => const [
              SystemTrayMenuEntry(
                id: 7,
                label: 'Open preferences',
                enabled: true,
                visible: true,
                separator: false,
                toggleType: SystemTrayMenuToggleType.none,
                toggleState: 0,
                destructive: false,
                children: [],
              ),
            ],
            onLoadSubmenu: (_, _) async => null,
            onInvokeMenu: onInvokeMenu ?? (_, _) => true,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final horizontal in [true, false]) {
    for (final source in SystemTrayItemSource.values) {
      testWidgets('icon-only $source horizontal=$horizontal retains hover tip', (
        tester,
      ) async {
        final item = _item(source);
        await tester.pumpWidget(_host(item: item, horizontal: horizontal));
        final button = find.byKey(systemTrayItemButtonKey(item.id));
        expect(tester.getSize(button), const Size.square(22));
        expect(
          tester.getSize(find.byKey(systemTrayItemIconKey(item.id))),
          const Size.square(18),
        );
        expect(find.text(item.title), findsNothing);
        expect(find.text('Tooltip title\nActivity & details'), findsNothing);
        final semantics = tester.widget<Semantics>(
          find.descendant(
            of: button,
            matching: find.byWidgetPredicate(
              (widget) => widget is Semantics && widget.properties.button == true,
            ),
          ),
        );
        expect(semantics.properties.label, item.title);
        expect(semantics.properties.value, 'Needs attention');

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(button));
        await tester.pump(const Duration(milliseconds: 499));
        expect(find.text('Tooltip title\nActivity & details'), findsNothing);
        await tester.pump(const Duration(milliseconds: 151));
        expect(find.text('Tooltip title\nActivity & details'), findsOneWidget);
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('title fallback and icon input still route activation and menu', (
    tester,
  ) async {
    final item = _item(SystemTrayItemSource.xEmbed, tooltip: false);
    final actions = <SystemTrayAction>[];
    final entries = <int>[];
    await tester.pumpWidget(
      _host(
        item: item,
        onInvoke: (_, action, _) {
          actions.add(action);
          return true;
        },
        onInvokeMenu: (_, id) {
          entries.add(id);
          return true;
        },
      ),
    );
    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, item.title);
    expect(find.text(item.title), findsNothing);
    final button = find.byKey(systemTrayItemButtonKey(item.id));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, buttons: kMiddleMouseButton);
    await tester.pump();
    expect(actions, [
      SystemTrayAction.activate,
      SystemTrayAction.secondaryActivate,
    ]);
    await tester.tap(button, buttons: kSecondaryMouseButton);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Open preferences'), findsOneWidget);
    await tester.tap(find.text('Open preferences'));
    await tester.pumpAndSettle();
    expect(entries, [7]);
    expect(find.text('Open preferences'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
