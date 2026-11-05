import 'package:flutter/material.dart';

/// Ilustración vectorial hecha con widgets: no descarga imágenes de Saba ni
/// depende de recursos remotos para mostrar la presentación estática.
class WellnessIllustration extends StatelessWidget {
  const WellnessIllustration({
    this.compact = false,
    this.type = 'medicine',
    super.key,
  });
  final bool compact;
  final String type;
  static const green = Color(0xFF167B57);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: SizedBox(
          width: 115,
          height: 125,
          child: switch (type) {
            'kit' => const _Kit(),
            'care' => const _Bottle(color: Color(0xFFDD8A56), label: 'CARE'),
            'vitamins' => const _Bottle(color: Color(0xFFCE9B3F), label: 'VIT'),
            _ => const _MedicineBox(),
          },
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 1.12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 470;
          // FittedBox mantiene la composición original incluso en un móvil.
          return FittedBox(
            child: SizedBox(
              width: 470,
              height: 420,
              child: Stack(
                children: [
                  Positioned(
                    left: 26,
                    top: 4,
                    child: Container(
                      width: 398,
                      height: 398,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD7EDE0),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 57,
                    top: 38,
                    child: Container(
                      width: 326,
                      height: 326,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .65),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 164,
                    top: 31,
                    child: Container(
                      width: 145,
                      height: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80),
                        border: Border.all(color: green, width: 9),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 113,
                    top: 115,
                    child: Container(
                      width: 241,
                      height: 249,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDF8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: .12),
                            offset: const Offset(0, 22),
                            blurRadius: 36,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 61,
                            height: 61,
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'JAE',
                            style: TextStyle(
                              color: green,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'CERCA DE TU BIENESTAR',
                            style: TextStyle(
                              color: green,
                              fontSize: 8,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 51,
                    top: 209,
                    child: SizedBox(
                      width: 102,
                      height: 171,
                      child: _Bottle(color: Color(0xFF5B98AD), label: 'CARE'),
                    ),
                  ),
                  const Positioned(
                    right: 44,
                    top: 253,
                    child: SizedBox(
                      width: 109,
                      height: 136,
                      child: _MedicineBox(),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 112,
                    child: Transform.rotate(
                      angle: -.16,
                      child: Container(
                        width: 105,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: green.withValues(alpha: .08),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFE39266),
                              size: 20,
                            ),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Bienestar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27,
                    top: 83,
                    child: Transform.rotate(
                      angle: -.35,
                      child: const Icon(
                        Icons.eco_rounded,
                        color: green,
                        size: 51,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 39,
                    bottom: 32,
                    child: Icon(
                      Icons.add_rounded,
                      color: green.withValues(alpha: .4),
                      size: 29 * scale.clamp(.8, 1.2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bottle extends StatelessWidget {
  const _Bottle({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 44,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ),
      Expanded(
        child: Container(
          width: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .12),
                blurRadius: 14,
                offset: const Offset(4, 9),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: color.withValues(alpha: .14),
                child: Column(
                  children: [
                    Icon(Icons.water_drop_outlined, color: color, size: 24),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 37,
                height: 3,
                color: color.withValues(alpha: .22),
              ),
              const SizedBox(height: 5),
              Container(
                width: 25,
                height: 3,
                color: color.withValues(alpha: .12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MedicineBox extends StatelessWidget {
  const _MedicineBox();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Transform.rotate(
      angle: -.06,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEADDC5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(5, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFE2A069),
                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.medication_outlined,
              color: Color(0xFFCB8850),
              size: 29,
            ),
            const SizedBox(height: 5),
            const Text(
              'JAE',
              style: TextStyle(
                color: Color(0xFF986F43),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(height: 10, color: const Color(0xFFF4E6CD)),
          ],
        ),
      ),
    ),
  );
}

class _Kit extends StatelessWidget {
  const _Kit();
  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 46,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WellnessIllustration.green, width: 5),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: 106,
          height: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6E6DE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: WellnessIllustration.green,
            size: 41,
          ),
        ),
      ],
    ),
  );
}
