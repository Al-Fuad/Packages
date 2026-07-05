import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securely/securely.dart';

/// A secure text field that interacts with [SecureKeyboard] rather than the system keyboard.
///
/// It supports standard Flutter [TextField] decorations and styles, giving developers
/// full customization capabilities while enforcing in-app secure keyboard usage.
class SecureTextField extends StatefulWidget {
  /// The controller that controls the text.
  final TextEditingController controller;

  /// The focus node that controls focus of this text field.
  final FocusNode? focusNode;

  /// Input decoration styling.
  final InputDecoration decoration;

  /// Style of the text.
  final TextStyle? style;

  /// Custom cursor color.
  final Color? cursorColor;

  /// Custom cursor width.
  final double cursorWidth;

  /// Custom cursor height.
  final double? cursorHeight;

  /// Custom cursor radius.
  final Radius? cursorRadius;

  /// Text alignment.
  final TextAlign textAlign;

  /// Text direction.
  final TextDirection? textDirection;

  /// Text capitalization style.
  final TextCapitalization textCapitalization;

  /// Minimum lines to display.
  final int? minLines;

  /// Maximum lines to display.
  final int? maxLines;

  /// Maximum character count.
  final int? maxLength;

  /// Input formatters to format the input as keys are pressed.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to obscure the input text (e.g. for passwords).
  final bool obscureText;

  /// Character used to obscure text.
  final String obscuringCharacter;

  /// Scroll padding for the text field inside a scroll view.
  final EdgeInsets scrollPadding;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when keyboard submit action is triggered.
  final ValueChanged<String>? onSubmitted;

  /// Tap callback.
  final GestureTapCallback? onTap;

  /// Callback when tapping outside the text field.
  final TapRegionCallback? onTapOutside;

  // --- Secure Keyboard Configurations ---

  /// Whether to automatically show the keyboard as a bottom sheet when focused.
  ///
  /// Set to `false` if displaying the [SecureKeyboard] inline in the widget tree.
  final bool showKeyboardBottomSheet;

  /// The keyboard layout type to display.
  final SecureKeyboardType keyboardType;

  /// Key scrambling configuration.
  final SecureKeyboardShuffle keyboardShuffleType;

  /// Behavior when screen recording/sharing is active.
  final SecureKeyboardObscureMode keyboardObscureMode;

  /// Custom theme for the keyboard.
  final SecureKeyboardTheme keyboardTheme;

  /// Whether the keyboard plays haptic feedback on tap.
  final bool enableHapticFeedback;

  /// Whether to automatically obscure the input text in the field when screen sharing is detected.
  final bool obscureOnScreenShare;

  /// Whether to use a modal bottom sheet (`showModalBottomSheet`) instead of a persistent bottom sheet (`showBottomSheet`).
  ///
  /// Defaults to `true`. When set to `false`, a persistent bottom sheet is shown,
  /// allowing users to interact with background elements like scrolling or tapping other widgets.
  final bool useModalBottomSheet;

  /// Callback when the secure keyboard visibility changes (e.g. bottom sheet opens/closes).
  final ValueChanged<bool>? onKeyboardVisible;

  const SecureTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    // Keyboard settings
    this.showKeyboardBottomSheet = true,
    this.useModalBottomSheet = true,
    this.keyboardType = SecureKeyboardType.numeric,
    this.keyboardShuffleType = SecureKeyboardShuffle.none,
    this.keyboardObscureMode = SecureKeyboardObscureMode.blockKeyboard,
    this.keyboardTheme = const SecureKeyboardTheme(),
    this.enableHapticFeedback = true,
    this.obscureOnScreenShare = true,
    this.onKeyboardVisible,
  });

  @override
  State<SecureTextField> createState() => _SecureTextFieldState();
}

class _SecureTextFieldState extends State<SecureTextField> {
  late FocusNode _focusNode;
  bool _isBottomSheetOpen = false;
  bool _ignoreNextFocus = false;
  PersistentBottomSheetController? _persistentBottomSheetController;

  // RASP screen recording state
  bool _isScreenRecording = false;
  StreamSubscription<bool>? _screenRecordingSubscription;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _setupScreenRecordingProtection();
  }

  @override
  void didUpdateWidget(covariant SecureTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != null && widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode!;
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    _screenRecordingSubscription?.cancel();
    _persistentBottomSheetController?.close();
    super.dispose();
  }

  void _closeBottomSheet() {
    if (!_isBottomSheetOpen) return;
    setState(() {
      _isBottomSheetOpen = false;
    });
    widget.onKeyboardVisible?.call(false);

    if (widget.useModalBottomSheet) {
      Navigator.of(context).pop();
    } else {
      _persistentBottomSheetController?.close();
      _persistentBottomSheetController = null;
    }
  }

  Future<void> _setupScreenRecordingProtection() async {
    if (!widget.obscureOnScreenShare) return;

    try {
      final isEmulator = await Securely.isEmulatorDetected();
      if (isEmulator)
        return; // Bypass screen recording blocks on emulators/simulators for testing
    } catch (_) {}

    try {
      final recording = await Securely.isScreenRecordingDetected();
      if (mounted) {
        setState(() {
          _isScreenRecording = recording;
        });
        final shouldBlock =
            recording &&
            widget.keyboardObscureMode ==
                SecureKeyboardObscureMode.blockKeyboard;
        if (shouldBlock) {
          _closeBottomSheet();
          _focusNode.unfocus();
        }
      }
    } catch (_) {}

    _screenRecordingSubscription = Securely.onScreenRecordingChanged.listen((
      recording,
    ) {
      if (mounted) {
        setState(() {
          _isScreenRecording = recording;
        });
        final shouldBlock =
            recording &&
            widget.keyboardObscureMode ==
                SecureKeyboardObscureMode.blockKeyboard;
        if (shouldBlock) {
          _closeBottomSheet();
          _focusNode.unfocus();
        }
      }
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_ignoreNextFocus) {
        _ignoreNextFocus = false;
        _focusNode.unfocus();
        return;
      }

      // Delay to let keyboard/bottom sheet open, then scroll into view
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _focusNode.hasFocus) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            alignment: 0.3, // Focus towards the upper part of the viewport
            curve: Curves.easeInOut,
          );
        }
      });

      if (widget.showKeyboardBottomSheet) {
        // Delay slightly to prevent keyboard overlap issues or focus fights
        Future.microtask(() => _showKeyboardBottomSheet());
      }
    } else {
      if (!widget.useModalBottomSheet) {
        _closeBottomSheet();
      }
    }
  }

  void _showKeyboardBottomSheet() {
    if (_isBottomSheetOpen || !mounted) return;
    setState(() {
      _isBottomSheetOpen = true;
    });
    widget.onKeyboardVisible?.call(true);

    // Scroll the field into view once bottom padding is updated
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.3,
          curve: Curves.easeInOut,
        );
      }
    });

    if (widget.useModalBottomSheet) {
      _showModalBottomSheet();
    } else {
      try {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold == null) {
          _showModalBottomSheet();
          return;
        }

        _persistentBottomSheetController = scaffold.showBottomSheet(
          (sheetContext) {
            return SecureKeyboard(
              controller: widget.controller,
              type: widget.keyboardType,
              shuffleType: widget.keyboardShuffleType,
              obscureMode: widget.keyboardObscureMode,
              theme: widget.keyboardTheme,
              enableHapticFeedback: widget.enableHapticFeedback,
              onDone: () {
                _persistentBottomSheetController?.close();
                if (widget.onSubmitted != null) {
                  widget.onSubmitted!(widget.controller.text);
                }
              },
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
        );

        _persistentBottomSheetController!.closed.then((_) {
          if (mounted) {
            final wasOpen = _isBottomSheetOpen;
            setState(() {
              _isBottomSheetOpen = false;
              _persistentBottomSheetController = null;
            });
            if (wasOpen) {
              widget.onKeyboardVisible?.call(false);
            }
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
            }
          }
        });
      } catch (_) {
        _showModalBottomSheet();
      }
    }
  }

  void _showModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, // NORMAL background (no dark overlay)
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              final wasOpen = _isBottomSheetOpen;
              _isBottomSheetOpen = false;
              if (wasOpen) {
                widget.onKeyboardVisible?.call(false);
              }
              _ignoreNextFocus = true;
              Future.delayed(const Duration(milliseconds: 50), () {
                _ignoreNextFocus = false;
              });
              _focusNode.unfocus();
            }
          },
          child: SecureKeyboard(
            controller: widget.controller,
            type: widget.keyboardType,
            shuffleType: widget.keyboardShuffleType,
            obscureMode: widget.keyboardObscureMode,
            theme: widget.keyboardTheme,
            enableHapticFeedback: widget.enableHapticFeedback,
            onDone: () {
              Navigator.pop(modalContext);
              if (widget.onSubmitted != null) {
                widget.onSubmitted!(widget.controller.text);
              }
            },
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        final wasOpen = _isBottomSheetOpen;
        setState(() {
          _isBottomSheetOpen = false;
        });
        if (wasOpen) {
          widget.onKeyboardVisible?.call(false);
        }
        _ignoreNextFocus = true;
        Future.delayed(const Duration(milliseconds: 50), () {
          _ignoreNextFocus = false;
        });
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      }
    });

    // Request focus back to the text field so it remains focused (cursor blinks, scroll padding remains active)
    Future.microtask(() {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If screen share is active and obscureOnScreenShare is true, force obscureText to true
    final shouldObscure =
        widget.obscureText ||
        (_isScreenRecording && widget.obscureOnScreenShare);
    // Deactivate text field inputs only if keyboardObscureMode is blockKeyboard and screen recording is active
    final isBlocked =
        _isScreenRecording &&
        widget.keyboardObscureMode == SecureKeyboardObscureMode.blockKeyboard;
    final isFieldEnabled = widget.enabled && !isBlocked;

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      style: widget.style,
      cursorColor: widget.cursorColor,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textCapitalization: widget.textCapitalization,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      enabled: isFieldEnabled,
      obscureText: shouldObscure,
      obscuringCharacter: widget.obscuringCharacter,
      scrollPadding: widget.scrollPadding,
      onChanged: widget.onChanged,
      onTap: () {
        if (widget.onTap != null) widget.onTap!();
        if (widget.showKeyboardBottomSheet &&
            !_isBottomSheetOpen &&
            isFieldEnabled) {
          _showKeyboardBottomSheet();
        }
      },
      onTapOutside: (event) {
        if (widget.onTapOutside != null) {
          widget.onTapOutside!(event);
        } else {
          // Unfocus by default when tapping outside
          _focusNode.unfocus();
        }
      },
      // IMPORTANT: By setting readOnly to true and showCursor to true,
      // Flutter maintains text selection and a blinking cursor but does
      // not open the native system soft keyboard.
      readOnly: true,
      showCursor: true,
      enableInteractiveSelection:
          false, // Disables copy, paste, select-all overlay for security
    );
  }
}
