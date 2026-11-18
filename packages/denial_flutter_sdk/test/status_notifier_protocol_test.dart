import 'dart:typed_data';

import 'package:denial_flutter_sdk/src/models/system_tray_item.dart';
import 'package:denial_flutter_sdk/src/services/status_notifier_protocol.dart';
import 'package:test/test.dart';

SystemTrayItem item({
  String tooltipTitle = '',
  String tooltipDescription = '',
  SystemTrayIconPixmap? pixmap,
}) => SystemTrayItem(
  id: 'quota',
  source: SystemTrayItemSource.statusNotifier,
  title: '42%',
  status: SystemTrayStatus.active,
  iconName: 'quota-icon',
  iconThemePath: '',
  iconPixmap: pixmap,
  menuAvailable: false,
  primaryOpensMenu: false,
  tooltipTitle: tooltipTitle,
  tooltipDescription: tooltipDescription,
);

void main() {
  test('full snapshots preserve tooltip text separately from SNI Title', () {
    final original = item(
      tooltipTitle: 'Magpie',
      tooltipDescription: ' <b>42%</b> remaining\nResets tomorrow ',
    );
    final decoded = StatusNotifierProtocol.decodeItems(
      StatusNotifierProtocol.encodeItems([original]),
    ).single;

    expect(decoded, original);
    expect(decoded.hashCode, original.hashCode);
    expect(decoded.title, '42%');
    expect(decoded.tooltipTitle, 'Magpie');
    expect(
      decoded.tooltipDescription,
      ' <b>42%</b> remaining\nResets tomorrow ',
    );
  });

  test('immutable metadata snapshots publish tooltip changes and clearing', () {
    final encoder = StatusNotifierUpdateEncoder();
    final decoder = StatusNotifierUpdateDecoder();
    decoder.decode(encoder.encode([item(tooltipTitle: 'Magpie')]));

    final changed = item(tooltipDescription: 'Resets tomorrow');
    expect(decoder.decode(encoder.encode([changed])).single, changed);
    final cleared = decoder.decode(encoder.encode([item()])).single;
    expect(cleared.tooltipTitle, isEmpty);
    expect(cleared.tooltipDescription, isEmpty);
    expect(cleared.title, '42%');
  });

  test(
    'tooltip-only pixel deltas retain pixels and clear both text fields',
    () {
      final pixmap = SystemTrayIconPixmap(
        width: 1,
        height: 1,
        rgba: Uint8List.fromList([1, 2, 3, 255]),
      );
      final encoder = StatusNotifierUpdateEncoder();
      final decoder = StatusNotifierUpdateDecoder();
      final initial = decoder
          .decode(encoder.encode([item(pixmap: pixmap)]))
          .single;

      void update(String title, String description) {
        final next = item(
          pixmap: pixmap,
          tooltipTitle: title,
          tooltipDescription: description,
        );
        final frame = encoder.encode([next]) as List<Object?>;
        expect(frame[0], isFalse);
        final changed = frame[2]! as List<Object?>;
        expect(changed, hasLength(1));
        expect((changed.single! as List<Object?>)[6], isTrue);
        final decoded = decoder.decode(frame).single;
        expect(decoded, next);
        expect(identical(decoded.iconPixmap, initial.iconPixmap), isTrue);
        expect(decoded.title, '42%');
      }

      update('Magpie', 'Resets tomorrow');
      update('Magpie quota', 'Resets tomorrow');
      update('Magpie quota', 'Resets in one hour');
      update('', '');
    },
  );

  test('tooltip title and description independently affect item equality', () {
    final baseline = item(tooltipTitle: 'Magpie', tooltipDescription: 'Quota');
    expect(item(tooltipTitle: 'Magpie', tooltipDescription: 'Quota'), baseline);
    expect(
      item(tooltipTitle: 'Other', tooltipDescription: 'Quota'),
      isNot(baseline),
    );
    expect(
      item(tooltipTitle: 'Magpie', tooltipDescription: 'Other'),
      isNot(baseline),
    );
  });

  test('legacy items default to empty tooltip text through snapshots', () {
    const legacy = SystemTrayItem(
      id: 'legacy',
      source: SystemTrayItemSource.xEmbed,
      title: 'Legacy title',
      status: SystemTrayStatus.active,
      iconName: '',
      iconThemePath: '',
      iconPixmap: null,
      menuAvailable: false,
      primaryOpensMenu: false,
    );
    final decoded = StatusNotifierProtocol.decodeItems(
      StatusNotifierProtocol.encodeItems([legacy]),
    ).single;
    expect(decoded.tooltipTitle, isEmpty);
    expect(decoded.tooltipDescription, isEmpty);
    expect(decoded.title, 'Legacy title');
  });
}
