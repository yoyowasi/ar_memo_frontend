import 'package:flutter/material.dart';

import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 정보'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: primaryColor),
            title: const Text('PlaceNote'),
            subtitle: const Text('나만의 여행을 지도에 기록하고 관리하세요.'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.verified_outlined, color: primaryColor),
            title: const Text('버전'),
            subtitle: Text('v$_appVersion ($_buildNumber)'),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined, color: primaryColor),
            title: const Text('고객 지원'),
            subtitle: const Text('support@travelmemo.app'),
          ),
          const SizedBox(height: 24),
          Text(
            '오픈소스 라이선스',
            style: heading2.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '설정 > 오픈소스 라이선스 메뉴에서 사용 중인 라이브러리의 라이선스를 확인할 수 있습니다.',
            style: bodyText2,
          ),
          const SizedBox(height: 24),
          Text(
            '문의하기',
            style: heading2.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '서비스 이용 중 불편 사항이 있다면 위의 이메일로 언제든지 연락 주세요.',
            style: bodyText2,
          ),
        ],
      ),
    );
  }
}
