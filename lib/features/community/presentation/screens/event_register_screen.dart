import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_success_screen.dart';

class EventRegisterScreen extends StatefulWidget {
  final EventModel event;

  const EventRegisterScreen({
    super.key,
    required this.event,
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
                    child: widget.event.coverImageFile != null
                        ? Image.file(
                            widget.event.coverImageFile!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : widget.event.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.event.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                                  child: Icon(Icons.event_outlined, color: textMuted, size: 28),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.event_outlined, color: textMuted, size: 28),
                              ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.event.dateString.isNotEmpty)
                          Text(
                            '\u{1F4C5} ${widget.event.dateString}${widget.event.timeString.isNotEmpty ? ' \u2022 ${widget.event.timeString}' : ''}',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        if (widget.event.eventType == 'In person' && widget.event.location.isNotEmpty)
                          Text(
                            '\u{1F4CD} ${widget.event.location}',
                            style: TextStyle(color: textMutedSubtle, fontSize: 10),
                          )
                        else if (widget.event.eventType == 'Online')
                          Text(
                            '\u{1F4F9} Online Event',
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
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Mark RSVP in controller so state persists in Event list
                  final ctrl = Get.isRegistered<CommunityController>()
                      ? Get.find<CommunityController>()
                      : null;
                  ctrl?.toggleRsvp(widget.event.id);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventSuccessScreen(event: widget.event),
                    ),
                  );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'community.confirmRegistration'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
              borderSide: BorderSide(color: textPrimary),
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
