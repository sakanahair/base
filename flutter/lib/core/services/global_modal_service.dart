import 'package:flutter/material.dart';
import '../../shared/widgets/customer_detail_modal.dart';
import '../../shared/widgets/chat_modal.dart';

class GlobalModalService extends ChangeNotifier {
  static final GlobalModalService _instance = GlobalModalService._internal();
  factory GlobalModalService() => _instance;
  GlobalModalService._internal();

  // 現在開いているモーダルの管理
  String? _currentOpenModal;
  String? get currentOpenModal => _currentOpenModal;

  // 顧客詳細モーダルを表示
  static Future<void> showCustomerDetail(
    BuildContext context, {
    required String customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    // 既存のモーダルを閉じる
    if (_instance._currentOpenModal != null) {
      Navigator.of(context).pop();
    }

    _instance._currentOpenModal = 'customer_detail_$customerId';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => CustomerDetailModal(
        customerId: customerId,
        customerName: customerName ?? '顧客',
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      ),
    );

    _instance._currentOpenModal = null;
  }

  // チャットモーダルを表示
  static Future<void> showChat(
    BuildContext context, {
    required String customerId,
    String? customerName,
    String? channel,
    bool isFromCustomerDetail = false,
  }) async {
    // 顧客詳細から開いた場合は、顧客詳細を閉じない
    if (!isFromCustomerDetail && _instance._currentOpenModal != null) {
      Navigator.of(context).pop();
    }

    _instance._currentOpenModal = 'chat_$customerId';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => ChatModal(
        customerId: customerId,
        customerName: customerName ?? '顧客',
        channel: channel ?? 'App',
      ),
    );

    _instance._currentOpenModal = null;
  }

  // 予約作成モーダルを表示（将来実装用）
  static Future<void> showAppointmentCreation(
    BuildContext context, {
    String? customerId,
    String? customerName,
  }) async {
    if (_instance._currentOpenModal != null) {
      Navigator.of(context).pop();
    }

    _instance._currentOpenModal = 'appointment_creation';

    // TODO: AppointmentCreationModalの実装後に置き換え
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('新規予約作成'),
        content: Text('顧客: ${customerName ?? "未選択"}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );

    _instance._currentOpenModal = null;
  }

  // すべてのモーダルを閉じる
  static void closeAllModals(BuildContext context) {
    if (_instance._currentOpenModal != null) {
      Navigator.of(context).pop();
      _instance._currentOpenModal = null;
    }
  }

  // モーダルが開いているかチェック
  static bool isModalOpen() {
    return _instance._currentOpenModal != null;
  }

  // 特定のモーダルが開いているかチェック
  static bool isSpecificModalOpen(String modalId) {
    return _instance._currentOpenModal == modalId;
  }
}