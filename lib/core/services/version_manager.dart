import 'dart:developer' as dev;
import 'package:flutter/widgets.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

class VersionManager with WidgetsBindingObserver {
  VersionManager._();
  static final VersionManager instance = VersionManager._();

  bool _isDialogShown = false;
  bool _initialized = false;

  // Callbacks — set by provider layer
  Future<UpdateStatus> Function()? _onCheckVersion;
  void Function(UpdateStatus status)? _onResumeResult;

  void init({
    required Future<UpdateStatus> Function() onCheckVersion,
    required void Function(UpdateStatus status) onResumeResult,
  }) {
    if (_initialized) return;
    _initialized = true;

    _onCheckVersion = onCheckVersion;
    _onResumeResult = onResumeResult;

    WidgetsBinding.instance.addObserver(this);
    dev.log('[VersionManager] Initialized', name: 'VersionManager');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
    _onCheckVersion = null;
    _onResumeResult = null;
    dev.log('[VersionManager] Disposed', name: 'VersionManager');
  }

  bool get isDialogShown => _isDialogShown;
  void setDialogShown(bool value) => _isDialogShown = value;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOnResume();
    }
  }

  Future<void> _checkOnResume() async {
    if (_onCheckVersion == null) return;

    dev.log('[VersionManager] App resumed — checking version', name: 'VersionManager');
    final status = await _onCheckVersion!();

    switch (status) {
      case UpdateStatus.maintenance:
      case UpdateStatus.forceUpdate:
        _onResumeResult?.call(status);
      case UpdateStatus.optionalUpdate:
      case UpdateStatus.none:
        break; // onResume'da opsiyonel gösterme
    }
  }
}
