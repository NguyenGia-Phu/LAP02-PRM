import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  patrolTest(
    'E2E User Flow: Login, Search, Tab Navigation, and Export PDF',
    ($) async {
      // 1. Mở App
      // Khởi chạy ứng dụng
      await $.pumpWidgetAndSettle(
        app.JournalTrendApp(
          fcmService: FcmService(),
          remoteConfigService: RemoteConfigService(),
        ),
      );

      // 2. Mở App -> Thấy màn hình Login
      expect($('TrendAnalyzer'), findsOneWidget);
      expect($('Sign in with Google'), findsOneWidget);

      // 3. Bấm "Sign In with Google"
      await $('Sign in with Google').tap();
      await $.pumpAndSettle();

      // 4. Nhập từ khóa "machine learning" -> Bấm Search
      await $(TextField).enterText('machine learning');
      await $('Search').tap();
      await $.pumpAndSettle();

      // 5. Chuyển sang Tab Journals (thông qua BottomNavigationBar hoặc TabBar)
      await $('Journals').tap();
      await $.pumpAndSettle();
      
      // Xác nhận hiển thị danh sách tạp chí
      expect($('Ranked Journals List'), findsOneWidget);

      // 6. Chuyển sang Tab Keywords
      await $('Keywords').tap();
      await $.pumpAndSettle();
      
      // Xác nhận hiển thị từ khóa
      expect($('Keyword Frequencies'), findsOneWidget);

      // 7. Chuyển sang Tab Profile
      await $('Profile').tap();
      await $.pumpAndSettle();
      
      // Nhấn nút Export PDF Report
      await $('Export Trend Report').tap();
      // Đợi sinh PDF và upload lên Firebase Storage hoàn tất
      await $.pumpAndSettle();

      // Kiểm tra xem URL hoặc thông báo thành công có xuất hiện không
      expect($('Report generated and uploaded successfully!'), findsOneWidget);
    },
  );
}
