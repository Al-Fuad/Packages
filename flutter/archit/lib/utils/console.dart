import 'dart:io';
import 'package:interact/interact.dart';

// ─────────────────────────────────────────────────────────────
//  ANSI
// ─────────────────────────────────────────────────────────────
const String _r = '\x1B[0m';
const String _b = '\x1B[1m';
const String _d = '\x1B[2m';
const String _gr = '\x1B[32m'; // green
const String _cy = '\x1B[36m'; // cyan
const String _ye = '\x1B[33m'; // yellow
const String _re = '\x1B[31m'; // red
const String _gy = '\x1B[90m'; // gray

class Console {
  // expose for other files
  static const String reset = _r;
  static const String green = _gr;
  static const String cyan = _cy;
  static const String yellow = _ye;
  static const String red = _re;
  static const String gray = _gy;
  static const String bold = _b;
  static const String dim = _d;

  // ── BANNER ─────────────────────────────────────────────
  static void printBanner() {
    print('');

    // figlet-style "Archit CLI"
    _printFiglet();

    print('');
    _printSubBar();
    print('');
    _bootSequence();
    print('');
  }

  static void _printFiglet() {
    final w = _w();
    // hand-crafted figlet for "Archit CLI"
    final lines = [
      '$_gy░▒▓${'█' * (w - 6)}▓▒░$_r\n',
      r'  ░▒▓  █████╗ ██████╗  ██████╗██╗  ██╗██╗████████╗     ██████╗██╗     ██╗  ▓▒░',
      r'  ░▒▓ ██╔══██╗██╔══██╗██╔════╝██║  ██║██║╚══██╔══╝    ██╔════╝██║     ██║  ▓▒░',
      r'  ░▒▓ ███████║██████╔╝██║     ███████║██║   ██║       ██║     ██║     ██║  ▓▒░',
      r'  ░▒▓ ██╔══██║██╔══██╗██║     ██╔══██║██║   ██║       ██║     ██║     ██║  ▓▒░',
      r'  ░▒▓ ██║  ██║██║  ██║╚██████╗██║  ██║██║   ██║       ╚██████╗███████╗██║  ▓▒░',
      r'  ░▒▓ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝        ╚═════╝╚══════╝╚═╝  ▓▒░',
    ];

    for (final line in lines) {
      print('$_cy$_b$line$_r');
    }
  }

  static void _printSubBar() {
    const version = '0.0.4';

    final w = _w();
    final inner = w - 2;

    // top fade bar
    print('$_gy░▒▓${'█' * (w - 6)}▓▒░$_r');

    // info row
    print('$_gy╔${'─' * inner}╗$_r');
    final tag = '  ARCHIT CLI  │  v$version  │  ARCH-GEN  │  DART  ';
    final pad = ' ' * (inner - tag.length).clamp(0, 999);
    print('$_gy║$_r$_cy$_b$tag$_r$pad$_gy║$_r');
    print('$_gy╚${'─' * inner}╝$_r');

    // bottom fade bar
    print('$_gy░▒▓${'█' * (w - 6)}▓▒░$_r');
  }

  static void _bootSequence() {
    final steps = [
      'INITIALIZING SCAFFOLD ENGINE',
      'LOADING ARCHITECTURE MODULES',
      'MOUNTING FEATURE REGISTRY   ',
      'SYSTEM READY                ',
    ];
    for (final s in steps) {
      stdout.write('  $_gy>$_r $_cy$s$_r $_gy');
      for (int i = 0; i < 10; i++) {
        stdout.write('.');
        sleep(const Duration(milliseconds: 20));
      }
      print('$_r $_gr${_b}OK$_r');
      sleep(const Duration(milliseconds: 60));
    }
  }

  // ── PANELS ─────────────────────────────────────────────
  /// ┌─[ LABEL ]──────────────────────────┐
  static void panelOpen(String label) {
    final w = _w();
    final tag = '─[ $label ]';
    final rest = '─' * (w - tag.length - 2).clamp(0, 999);
    print('\n$_cy┌$tag$rest┐$_r');
  }

  static void panelClose() {
    stdout.write('$_cy└${'─' * (_w() - 2)}┘$_r\n');
  }

  static void panelRow(String content) {
    final w = _w();
    final inner = w - 6;
    final padded = content.padRight(inner);
    print(
        '$_cy│$_r  ${padded.substring(0, inner.clamp(0, padded.length))}  $_cy│$_r');
  }

  /// ╔─[ STATUS ]────────────╗  (double line variant)
  static void statusPanelOpen(String label) {
    final w = _w();
    final tag = '─[ $label ]';
    final rest = '─' * (w - tag.length - 4).clamp(0, 999);
    print('\n$_gr╔$tag$rest╗$_r');
  }

  static void statusPanelClose() {
    print('$_gr╚${'─' * (_w() - 2)}╝$_r');
  }

  static void statusPanelRow(String content) {
    final w = _w();
    final inner = w - 6;
    final padded = content.padRight(inner);
    print(
        '$_gr║$_r  ${padded.substring(0, inner.clamp(0, padded.length))}  $_gr║$_r');
  }

  // ── PROGRESS BAR ───────────────────────────────────────
  /// Renders inline: ██████░░░░ 60% BUILDING
  static void progressBar(String label, int percent, {String status = ''}) {
    final barW = 24;
    final filled = (barW * percent / 100).round();
    final empty = barW - filled;
    final bar = '$_gr${'█' * filled}$_gy${'░' * empty}$_r';
    stdout.write('\r  $bar  $_cy$_b$percent%$_r  $_ye$status$_r   ');
    if (percent >= 100) print('');
  }

  // ── STATUS MESSAGES ────────────────────────────────────
  static void success(String msg) => print('\n  $_gr[ OK ]$_r  $msg');

  static void error(String msg) => print('\n  $_re[ERR ]$_r  $_re$msg$_r');

  static void info(String msg) => print('  $_cy[ >> ]$_r  $msg');

  static void warning(String msg) => print('  $_ye[WARN]$_r  $_ye$msg$_r');

  static void step(String msg) {
    print('');
    print('  $_cy$_b▶  $msg$_r');
  }

  static void separator() => print('$_gy  ${'─' * (_w() - 2)}$_r');

  // ── TYPEWRITER ─────────────────────────────────────────
  static void typewriter(String text, {int delayMs = 18, String color = _cy}) {
    stdout.write(color);
    for (final char in text.split('')) {
      stdout.write(char);
      sleep(Duration(milliseconds: delayMs));
    }
    stdout.write(_r);
    print('');
  }

  // ── PROMPT (plain) ─────────────────────────────────────
  static String? prompt(String message, {String? defaultVal}) {
    final def = defaultVal != null ? ' $_gy(default: $defaultVal)$_r' : '';
    stdout.write('\n  $_cy\$$_r $_b$message$_r$def $_cy›$_r ');
    final input = stdin.readLineSync()?.trim();
    if ((input == null || input.isEmpty) && defaultVal != null)
      return defaultVal;
    return input;
  }

  // ── INTERACT: single select ────────────────────────────
  /// Arrow-key select — returns chosen index
  static int selectFromList(String title, List<String> options) {
    print('');
    _sectionTag(title);
    return Select(
      prompt: '',
      options: options,
    ).interact();
  }

  // ── INTERACT: multi select ─────────────────────────────
  /// Checkbox select — returns list of chosen indices
  static List<int> selectMultipleFromList(String title, List<String> options) {
    print('');
    _sectionTag(title);
    return MultiSelect(
      prompt: '',
      options: options,
      defaults: List.filled(options.length, true),
    ).interact();
  }

  // ── INTERACT: text input ───────────────────────────────
  static String inputText(String message, {String defaultVal = ''}) {
    print('');
    _sectionTag(message);
    return Input(
      prompt: '',
      defaultValue: defaultVal,
    ).interact();
  }

  // ── FEATURE / USECASE LISTS ───────────────────────────
  static void printFeatureList(List<String> features) {
    panelOpen('FEATURE REGISTRY');
    if (features.isEmpty) {
      panelRow('$_gy  [ no features registered yet ]$_r');
    } else {
      for (int i = 0; i < features.length; i++) {
        panelRow(
            '$_gr${(i + 1).toString().padLeft(2, '0')}$_r  $_gy│$_r  ${features[i]}');
      }
    }
    panelClose();
  }

  static void printUsecaseList(String feature, List<String> usecases) {
    panelOpen('USECASES  ›  $feature');
    if (usecases.isEmpty) {
      panelRow('$_gy  [ no usecases registered yet ]$_r');
    } else {
      for (int i = 0; i < usecases.length; i++) {
        panelRow(
            '$_gr${(i + 1).toString().padLeft(2, '0')}$_r  $_gy│$_r  ${usecases[i]}');
      }
    }
    panelClose();
  }

  // ── HELPERS ────────────────────────────────────────────
  static void _sectionTag(String label) {
    print('  $_gy┌─[ $_cy$_b$label$_r $_gy]$_r');
  }

  static int _w() {
    try {
      return stdout.terminalColumns.clamp(64, 120);
    } catch (_) {
      return 80;
    }
  }
}
