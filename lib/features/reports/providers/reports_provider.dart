import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/features/reports/models/report_data.dart';
import 'package:last/features/reports/services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider({ReportsService? service})
      : _service = service ?? createReportsService();

  final ReportsService _service;
  ReportData? _data;
  bool _loading = false;
  String? _error;
  StreamSubscription<ReportData>? _sub;

  ReportData? get data => _data;
  bool get isLoading => _loading;
  String? get error => _error;

  void startListening({String? officerId}) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.watchReportData(officerId: officerId).listen(
      (data) {
        _data = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load reports';
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> load({String? officerId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _service.getReportData(officerId: officerId);
    } catch (_) {
      _error = 'Failed to load reports';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
