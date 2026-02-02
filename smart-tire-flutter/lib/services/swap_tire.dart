import 'package:flutter/material.dart';
import '../providers/app_state.dart';

// ตัวจัดการการสลับล้อ (รองรับ preview ยางที่ 2 และ confirm)
class TireSwapManager {
  bool isSwappingMode = false;     // เปิด/ปิดโหมดสลับล้อ
  String? selectedFirstTire;       // ตำแหน่งยางที่ 1 (ถูกเลือกก่อน)
  String? selectedSecondTire;      // ตำแหน่งยางที่ 2 (preview ก่อน confirm)

  // รีเซ็ตสถานะทั้งหมด
  void resetSelection() {
    isSwappingMode = false;
    selectedFirstTire = null;
    selectedSecondTire = null;
  }

  // รีเซ็ตเฉพาะการเลือกยาง (ไม่ปิดโหมด)
  void clearSelections() {
    selectedFirstTire = null;
    selectedSecondTire = null;
  }

  // เปิด/ปิดโหมดสลับล้อ (และล้าง selection)
  void toggleSwapMode() {
    isSwappingMode = !isSwappingMode;
    selectedFirstTire = null;
    selectedSecondTire = null;
  }

  // เลือกล้อแรก
  void selectFirstTire(String position) {
    selectedFirstTire = position;
    selectedSecondTire = null;
  }

  // เลือกยางที่สอง (preview)
  void selectSecondTire(String position) {
    selectedSecondTire = position;
  }

  // ยกเลิกยางที่สอง (แต่เก็บยางแรกไว้)
  void clearSecondTire() {
    selectedSecondTire = null;
  }

  // ตรวจสอบสถานะการเลือก
  bool isFirstTireSelected(String position) {
    return selectedFirstTire == position;
  }

  bool isSecondTireSelected(String position) {
    return selectedSecondTire == position;
  }

  // ข้อความ preview/confirm
  String getSwapPreviewMessage() {
    if (selectedFirstTire == null || selectedSecondTire == null) return '';
    final a = _getPositionText(selectedFirstTire!);
    final b = _getPositionText(selectedSecondTire!);
    return 'ต้องการสลับ $a ↔ $b ใช่หรือไม่?';
  }

  String getSwapCompleteMessage(String firstPos, String secondPos) {
    String firstText = _getPositionText(firstPos);
    String secondText = _getPositionText(secondPos);
    return 'สลับล้อ $firstText ↔ $secondText เรียบร้อยแล้ว';
  }

  // ทำการสลับจริง (เรียกจาก UI เมื่อผู้ใช้ยืนยัน)
  void performSwapConfirmed(
    BuildContext context,
    AppState appState,
    VoidCallback onSwapComplete,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    if (selectedFirstTire == null || selectedSecondTire == null) {
      // ไม่มีข้อมูลครบ → แจ้งเตือน
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้เลือกยางครบ 2 ตำแหน่ง'), duration: Duration(seconds: 2)),
      );
      return;
    }

    final firstPos = selectedFirstTire!;
    final secondPos = selectedSecondTire!;

    // สลับตำแหน่งใน AppState (สมมติ appState.swapTires รับ map)
    appState.swapTires({
      firstPos: secondPos,
      secondPos: firstPos,
    });

    final message = getSwapCompleteMessage(firstPos, secondPos);

    // รีเซ็ตสถานะหลังสลับเสร็จ
    resetSelection();
    onSwapComplete();

    // แจ้งผล
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // แปลงรหัสตำแหน่งล้อเป็นข้อความไทย
  String _getPositionText(String position) {
    switch (position) {
      case 'FL':
        return 'หน้าซ้าย';
      case 'FR':
        return 'หน้าขวา';
      case 'RL':
        return 'หลังซ้าย';
      case 'RR':
        return 'หลังขวา';
      case 'SPARE':
        return 'อะไหล่';
      default:
        return position;
    }
  }
}