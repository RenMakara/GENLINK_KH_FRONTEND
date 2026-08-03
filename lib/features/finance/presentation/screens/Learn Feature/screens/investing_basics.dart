import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Learn%20Feature/screens/investing_quiz.dart';

class InvestingBasicsScreen extends StatelessWidget {
  const InvestingBasicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: textPrimary,
          ),
        ),

        title: Text(
          'Investing Basics',
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // LESSON HERO
              // =================================================
              Container(
                width: double.infinity,
                height: 145,

                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: border),
                ),

                child: Stack(
                  children: [
                    // Grid-like decoration
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter(isDark: isDark)),
                    ),

                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.auto_graph_rounded,
                            color: textPrimary.withValues(alpha: .75),
                            size: 30,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '6 min read',
                            style: TextStyle(color: textMuted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // TAGS
              // =================================================
              Row(
                children: [
                  _Tag(
                    title: 'Finance',
                    background: primary,
                    foreground: textInverse,
                  ),

                  const SizedBox(width: 6),

                  _Tag(
                    title: 'Beginner',
                    background: surface,
                    foreground: textMuted,
                    border: border,
                  ),

                  const SizedBox(width: 6),

                  _Tag(
                    title: '+100 XP',
                    background: surface,
                    foreground: textMuted,
                    border: border,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =================================================
              // TITLE
              // =================================================
              Text(
                'Investing Basics: Build Wealth Over Time',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Learn how to make your money work for you. '
                'This lesson covers the fundamentals of investing '
                'for beginners in Cambodia and Southeast Asia.',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // KEY POINTS
              // =================================================
              Text(
                'Key Points',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              _KeyPoint(
                number: '1',
                text: 'Understand risk vs. return in investments',
                background: surfaceSecondary,
                textPrimary: textPrimary,
              ),

              _KeyPoint(
                number: '2',
                text: 'Start with index funds for diversification',
                background: surfaceSecondary,
                textPrimary: textPrimary,
              ),

              _KeyPoint(
                number: '3',
                text: 'The power of compound interest over time',
                background: surfaceSecondary,
                textPrimary: textPrimary,
              ),

              _KeyPoint(
                number: '4',
                text: 'Set realistic investment goals for your income',
                background: surfaceSecondary,
                textPrimary: textPrimary,
              ),

              _KeyPoint(
                number: '5',
                text: 'Avoid common investing mistakes as a beginner',
                background: surfaceSecondary,
                textPrimary: textPrimary,
              ),

              const SizedBox(height: 12),

              Divider(color: border, height: 1),

              const SizedBox(height: 10),

              Text('Quiz', style: TextStyle(color: textMuted, fontSize: 9)),

              const SizedBox(height: 3),

              Text(
                'Test your knowledge and track your progress.',
                style: TextStyle(color: textMuted, fontSize: 9),
              ),

              const SizedBox(height: 12),

              // =================================================
              // START QUIZ
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 44,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvestingQuizScreen(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: textInverse,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: const Text(
                    'Start Quiz →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// TAG
// =============================================================

class _Tag extends StatelessWidget {
  final String title;
  final Color background;
  final Color foreground;
  final Color? border;

  const _Tag({
    required this.title,
    required this.background,
    required this.foreground,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border!) : null,
      ),

      child: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================
// KEY POINT
// =============================================================

class _KeyPoint extends StatelessWidget {
  final String number;
  final String text;
  final Color background;
  final Color textPrimary;

  const _KeyPoint({
    required this.number,
    required this.text,
    required this.background,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),

      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,

            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),

            alignment: Alignment.center,

            child: Text(
              number,
              style: TextStyle(
                color: textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// BACKGROUND GRID
// =============================================================

class _GridPainter extends CustomPainter {
  final bool isDark;

  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: .025)
          : Colors.black.withValues(alpha: .025)
      ..strokeWidth = .5;

    const spacing = 12.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
