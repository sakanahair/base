import 'package:flutter/material.dart';
import '../services/global_modal_service.dart';

// BuildContextの拡張機能
extension ContextExtensions on BuildContext {
  // 顧客詳細モーダルを開く
  Future<void> showCustomerDetail({
    required String customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    return GlobalModalService.showCustomerDetail(
      this,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }
  
  // チャットモーダルを開く
  Future<void> showCustomerChat({
    required String customerId,
    String? customerName,
    String? channel,
    bool isFromCustomerDetail = false,
  }) async {
    return GlobalModalService.showChat(
      this,
      customerId: customerId,
      customerName: customerName,
      channel: channel,
      isFromCustomerDetail: isFromCustomerDetail,
    );
  }
  
  // 予約作成モーダルを開く
  Future<void> showAppointmentCreation({
    String? customerId,
    String? customerName,
  }) async {
    return GlobalModalService.showAppointmentCreation(
      this,
      customerId: customerId,
      customerName: customerName,
    );
  }
  
  // すべてのモーダルを閉じる
  void closeAllModals() {
    GlobalModalService.closeAllModals(this);
  }
  
  // モーダルが開いているかチェック
  bool get isModalOpen => GlobalModalService.isModalOpen();
  
  // 特定のモーダルが開いているかチェック
  bool isSpecificModalOpen(String modalId) {
    return GlobalModalService.isSpecificModalOpen(modalId);
  }
}