import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import 'event_success_screen.dart';

class EventRegisterScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const EventRegisterScreen({
    super.key,
    required this.eventData,
  });

  @override
  State<EventRegisterScreen> createState() => _EventRegisterScreenState();
}

class _EventRegisterScreenState extends State<EventRegisterScreen> {
  final _fullNameController = TextEditingController(text: 'Enat Sokny');
  final _emailController = TextEditingController(text: 'enat.sokny@aupp.edu.kh');
  final _phoneController = TextEditingController(text: '+855 12 345 678');

  String selectedUniversity = 'ACLEDA University of Business';
  String selectedFaculty = 'Computer Engineering';
  String selectedYear = 'Year 3';
  bool agreedToTerms = true;

  final List<String> universities = [
    'ACLEDA University of Business',
    'Royal University of Phnom Penh (RUPP)',
    'Cambodia Academy of Digital Technology (CADT)',
    'Institute of Technology of Cambodia (ITC)',
    'American University of Phnom Penh (AUPP)',
  ];

  final List<String> faculties = [
    'Computer Engineering',
    'Software Development',
    'Data Science & AI',
    'Business Administration',
  ];

  final List<String> studyYears = ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Fresh Graduate'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    final textMutedSubtle = isDark ? Colors.white38 : AppColors.lightTextMuted;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'community.registerForEvent'.tr,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Tile Summary Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.eventData['image'] as String? ??
                          'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=300',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.eventData['title'] as String? ?? 'Flutter Workshop 2026',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "📅 25 July 2026 • 9:00 AM - 4:00 PM",
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        Text(
                          "📍 ACLEDA University, Phnom Penh",
                          style: TextStyle(color: textMutedSubtle, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Input Fields
            _buildInputField(context, 'community.fullNameReq'.tr, _fullNameController),
            const SizedBox(height: 14),

            _buildDropdownField(
              context,
              'community.universityReq'.tr,
              selectedUniversity,
              universities,
              (val) => setState(() => selectedUniversity = val!),
            ),
            const SizedBox(height: 14),

            _buildDropdownField(
              context,
              'community.facultyReq'.tr,
              selectedFaculty,
              faculties,
              (val) => setState(() => selectedFaculty = val!),
            ),
            const SizedBox(height: 14),

            _buildDropdownField(
              context,
              'community.yearOfStudyReq'.tr,
              selectedYear,
              studyYears,
              (val) => setState(() => selectedYear = val!),
            ),
            const SizedBox(height: 14),

            _buildInputField(context, 'community.emailReq'.tr, _emailController),
            const SizedBox(height: 14),

            _buildInputField(context, 'community.phoneNumberReq'.tr, _phoneController),
            const SizedBox(height: 16),

            // Checkbox Terms
            Row(
              children: [
                Checkbox(
                  value: agreedToTerms,
                  activeColor: const Color(0xFF6D28D9),
                  onChanged: (val) => setState(() => agreedToTerms = val ?? true),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'community.iAgreeTerms'.tr,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'community.termsAndConditions'.tr,
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventSuccessScreen(eventData: widget.eventData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.communityAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'community.confirmRegistration'.tr,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightBgSecondary;
    final dropdownBg = isDark ? const Color(0xFF18181B) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: dropdownBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
