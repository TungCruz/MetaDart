import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF151515), Color(0xFF080808)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 55, 24, 25),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BrandColumn(),
                          const SizedBox(height: 35),
                          _FooterColumn(
                            title: 'LIÊN KẾT',
                            items: [
                              'Trang chủ',
                              'Phim đang chiếu',
                              'Phim sắp chiếu',
                            ],
                          ),
                          const SizedBox(height: 30),
                          _FooterColumn(
                            title: 'HỖ TRỢ',
                            items: [
                              'Liên hệ',
                              'Điều khoản',
                              'Chính sách bảo mật',
                            ],
                          ),
                        ],
                      );
                    }

                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _BrandColumn()),
                        Expanded(
                          child: _FooterColumn(
                            title: 'LIÊN KẾT',
                            items: [
                              'Trang chủ',
                              'Phim đang chiếu',
                              'Phim sắp chiếu',
                            ],
                          ),
                        ),
                        Expanded(
                          child: _FooterColumn(
                            title: 'HỖ TRỢ',
                            items: [
                              'Liên hệ',
                              'Điều khoản',
                              'Chính sách bảo mật',
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 20),
                Text(
                  '© ${DateTime.now().year} Meta Cinema. All rights reserved.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFF40612)],
            ).createShader(bounds);
          },
          child: const Text(
            'META CINEMA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Trải nghiệm điện ảnh đỉnh cao với công nghệ hiện đại nhất.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text(
              item,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
