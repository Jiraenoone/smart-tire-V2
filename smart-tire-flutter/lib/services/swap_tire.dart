import 'package:flutter/material.dart';
import '../providers/app_state.dart';

class TireSwapManager {
  bool isSwappingMode = false;
  String? selectedFirstTire;

  void resetSelection() {
    isSwappingMode = false;
    selectedFirstTire = null;
  }

  void toggleSwapMode() {
    isSwappingMode = !isSwappingMode;
    selectedFirstTire = null;
  }

  void selectFirstTire(String position) {
    selectedFirstTire = position;
  }

  bool isFirstTireSelected(String position) {
    return selectedFirstTire == position;
  }

  String getSnackBarMessage(String position) {
    String positionText = _getPositionText(position);
    if (selectedFirstTire == null) {
      return 'เลือกแล้ว $positionText กดที่ล้อที่ 2 ที่ต้องการสลับ';
    }
    return 'เลือกล้ออีกตัวที่ต้องการสลับ';
  }

  String getSwapCompleteMessage(String firstPos, String secondPos) {
    String firstText = _getPositionText(firstPos);
    String secondText = _getPositionText(secondPos);
    return 'สลับล้อ $firstText กับ $secondText เรียบร้อยแล้ว';
  }

  void performSwap(
    BuildContext context,
    AppState appState,
    String position,
    VoidCallback onSwapComplete,
  ) {
    if (selectedFirstTire == null) {
      selectFirstTire(position);
    } else if (selectedFirstTire != position) {
      final firstPos = selectedFirstTire!;

      appState.swapTires({
        firstPos: position,
        position: firstPos,
      });

      final message = getSwapCompleteMessage(firstPos, position);
      resetSelection();
      onSwapComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เลือกล้ออีกตัวที่ต้องการสลับ'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

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
