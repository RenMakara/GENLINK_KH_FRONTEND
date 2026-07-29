import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register for Event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "📅 25 July 2026 • 9:00 AM - 4:00 PM",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const Text(
                          "📍 ACLEDA University, Phnom Penh",
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Input Fields
            _buildInputField("Full Name *", _fullNameController),
            const SizedBox(height: 14),

            _buildDropdownField(
              "University *",
              selectedUniversity,
              universities,
              (val) => setState(() => selectedUniversity = val!),
            ),
            const SizedBox(height: 14),

            _buildDropdownField(
              "Faculty *",
              selectedFaculty,
              faculties,
              (val) => setState(() => selectedFaculty = val!),
            ),
            const SizedBox(height: 14),

            _buildDropdownField(
              "Year of Study *",
              selectedYear,
              studyYears,
              (val) => setState(() => selectedYear = val!),
            ),
            const SizedBox(height: 14),

            _buildInputField("Email *", _emailController),
            const SizedBox(height: 14),

            _buildInputField("Phone Number *", _phoneController),
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
                      text: "I agree to the event ",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      children: const [
                        TextSpan(
                          text: "terms and conditions",
                          style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
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
                child: const Text(
                  "Confirm Registration",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
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
    String label,
    String currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF18181B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
