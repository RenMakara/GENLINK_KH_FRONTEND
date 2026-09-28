import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/opportunity_model.dart';
import 'package:genlink_frontend/features/community/domain/models/event_requests.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/opportunity_card_widget.dart';
import 'package:genlink_frontend/features/community/presentation/screens/opportunity_details_screen.dart';

class MockCommunityRepositoryForOpportunity extends Fake
    implements CommunityRepository {
  List<OpportunityModel> mockOpportunities = [
    OpportunityModel(
      id: '1',
      title: 'Mobile App Developer Internship',
      organization: 'ACLEDA Bank Plc.',
      description: 'Join our digital banking engineering team.',
      type: 'INTERNSHIP',
      location: 'Phnom Penh, Cambodia',
      applyLink: 'https://careers.acledabank.com.kh/apply/1',
      deadline: DateTime.now().add(const Duration(days: 14)),
      savedByMe: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    OpportunityModel(
      id: '2',
      title: 'CADT Full Tech Scholarship 2026',
      organization: 'Cambodia Academy of Digital Technology',
      description: '100% tuition coverage for computer science.',
      type: 'SCHOLARSHIP',
      location: 'Phnom Penh',
      applyLink: 'https://cadt.edu.kh/scholarships/2026',
      deadline: DateTime.now().add(const Duration(days: 2)),
      savedByMe: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<OpportunityModel>> getOpportunities({
    String? type,
    bool includeExpired = false,
    int page = 0,
    int size = 20,
  }) async {
    if (type != null && type.isNotEmpty && type != 'All') {
      return mockOpportunities
          .where((o) => o.type.toUpperCase() == type.toUpperCase())
          .toList();
    }
    return mockOpportunities;
  }

  @override
  Future<EventPageModel<OpportunityModel>> getOpportunitiesPage({
    String? type,
    bool includeExpired = false,
    int page = 1,
    int limit = 20,
  }) async {
    final content = await getOpportunities(
      type: type,
      includeExpired: includeExpired,
      page: page - 1,
      size: limit,
    );
    return EventPageModel<OpportunityModel>.fromContent(
      content,
      page: page - 1,
      size: limit,
      hasNext: content.length >= limit,
    );
  }

  @override
  Future<OpportunityModel> getOpportunityDetails(String opportunityId) async {
    return mockOpportunities.firstWhere((o) => o.id == opportunityId);
  }

  @override
  Future<bool> toggleSaveOpportunity(
    String opportunityId,
    bool currentlySaved,
  ) async {
    final idx = mockOpportunities.indexWhere((o) => o.id == opportunityId);
    if (idx != -1) {
      final current = mockOpportunities[idx];
      mockOpportunities[idx] = current.copyWith(savedByMe: !currentlySaved);
      return !currentlySaved;
    }
    return false;
  }

  @override
  Future<OpportunityModel> createOpportunity({
    required String title,
    String? organization,
    String? type,
    String? description,
    String? location,
    String? applyLink,
    DateTime? deadline,
  }) async {
    final newOpp = OpportunityModel(
      id: '99',
      title: title,
      organization: organization ?? '',
      description: description ?? '',
      type: type ?? 'JOB',
      location: location ?? '',
      applyLink: applyLink ?? '',
      deadline: deadline,
    );
    mockOpportunities.add(newOpp);
    return newOpp;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpportunityModel unit tests', () {
    test('fromJson parses full backend payload correctly', () {
      final json = {
        'id': 10,
        'title': 'Flutter Senior Engineer',
        'organization': 'ACLEDA Bank',
        'description': 'Lead mobile app development.',
        'type': 'JOB',
        'location': 'Phnom Penh',
        'applyLink': 'https://acledabank.com.kh/job/10',
        'deadline': '2026-12-31T23:59:59',
        'savedByMe': true,
        'createdAt': '2026-09-01T10:00:00',
      };

      final model = OpportunityModel.fromJson(json);

      expect(model.id, '10');
      expect(model.title, 'Flutter Senior Engineer');
      expect(model.organization, 'ACLEDA Bank');
      expect(model.type, 'JOB');
      expect(model.displayType, 'Job');
      expect(model.location, 'Phnom Penh');
      expect(model.applyLink, 'https://acledabank.com.kh/job/10');
      expect(model.savedByMe, isTrue);
      expect(model.deadline, isNotNull);
      expect(model.daysLeft, isNotNull);
    });

    test('displayType maps correctly for known types', () {
      expect(
        const OpportunityModel(
          id: '1',
          title: '',
          organization: '',
          description: '',
          type: 'INTERNSHIP',
        ).displayType,
        'Internship',
      );
      expect(
        const OpportunityModel(
          id: '2',
          title: '',
          organization: '',
          description: '',
          type: 'SCHOLARSHIP',
        ).displayType,
        'Scholarship',
      );
      expect(
        const OpportunityModel(
          id: '3',
          title: '',
          organization: '',
          description: '',
          type: 'HACKATHON',
        ).displayType,
        'Hackathon',
      );
      expect(
        const OpportunityModel(
          id: '4',
          title: '',
          organization: '',
          description: '',
          type: 'VOLUNTEER',
        ).displayType,
        'Volunteer',
      );
      expect(
        const OpportunityModel(
          id: '5',
          title: '',
          organization: '',
          description: '',
          type: 'OTHER',
        ).displayType,
        'Other',
      );
    });

    test('daysLeft and isExpiringSoon calculations', () {
      final expiringSoon = OpportunityModel(
        id: '1',
        title: 'Soon',
        organization: 'Org',
        description: 'Desc',
        type: 'JOB',
        deadline: DateTime.now().add(const Duration(days: 2)),
      );
      expect(expiringSoon.daysLeft, lessThanOrEqualTo(3));
      expect(expiringSoon.isExpiringSoon, isTrue);

      final notExpiringSoon = OpportunityModel(
        id: '2',
        title: 'Later',
        organization: 'Org',
        description: 'Desc',
        type: 'JOB',
        deadline: DateTime.now().add(const Duration(days: 30)),
      );
      expect(notExpiringSoon.daysLeft, greaterThan(7));
      expect(notExpiringSoon.isExpiringSoon, isFalse);
    });
  });

  group('CommunityController Opportunity tests', () {
    late CommunityController controller;
    late MockCommunityRepositoryForOpportunity repo;

    setUp(() {
      Get.reset();
      repo = MockCommunityRepositoryForOpportunity();
      controller = CommunityController(repository: repo);
    });

    tearDown(() {
      Get.reset();
    });

    test('fetchOpportunities loads items and filters by type', () async {
      await controller.fetchOpportunities();
      expect(controller.opportunities.length, 2);

      controller.filterOpportunitiesByType('Scholarship');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.selectedOpportunityType.value, 'Scholarship');
      expect(controller.opportunities.length, 1);
      expect(controller.opportunities.first.type, 'SCHOLARSHIP');

      controller.filterOpportunitiesByType('All');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.opportunities.length, 2);
    });

    test(
      'toggleOpportunityBookmark toggles saved status optimistically and resolves',
      () async {
        await controller.fetchOpportunities();
        expect(controller.opportunities[0].savedByMe, isFalse);

        final result1 = await controller.toggleOpportunityBookmark('1');
        expect(result1, isTrue);
        expect(controller.opportunities[0].savedByMe, isTrue);

        final result2 = await controller.toggleOpportunityBookmark('1');
        expect(result2, isFalse);
        expect(controller.opportunities[0].savedByMe, isFalse);
      },
    );
  });

  group('Opportunity Widgets and Screens tests', () {
    late MockCommunityRepositoryForOpportunity repo;

    setUp(() {
      Get.reset();
      repo = MockCommunityRepositoryForOpportunity();
      Get.put(CommunityController(repository: repo));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets(
      'OpportunityCardWidget renders title, organization, and badges',
      (tester) async {
        final opportunity = OpportunityModel(
          id: '1',
          title: 'Software Engineer Internship',
          organization: 'ACLEDA Bank',
          description: 'Exciting summer internship for tech students.',
          type: 'INTERNSHIP',
          location: 'Phnom Penh',
          deadline: DateTime.now().add(const Duration(days: 10)),
          savedByMe: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OpportunityCardWidget(
                opportunity: opportunity,
                onBookmarkToggle: () {},
              ),
            ),
          ),
        );

        expect(find.text('Software Engineer Internship'), findsOneWidget);
        expect(find.text('ACLEDA Bank'), findsOneWidget);
        expect(find.text('Internship'), findsOneWidget);
        expect(find.text('Phnom Penh'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_outline_rounded), findsOneWidget);
      },
    );

    testWidgets('OpportunityDetailsScreen renders full view and details', (
      tester,
    ) async {
      final opportunity = OpportunityModel(
        id: '2',
        title: 'Full Tech Scholarship',
        organization: 'CADT Cambodia',
        description:
            'Comprehensive scholarship program for outstanding students.',
        type: 'SCHOLARSHIP',
        location: 'Phnom Penh, Cambodia',
        applyLink: 'https://cadt.edu.kh/apply',
        deadline: DateTime.now().add(const Duration(days: 20)),
        savedByMe: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: OpportunityDetailsScreen(opportunity: opportunity)),
      );

      expect(find.text('Full Tech Scholarship'), findsOneWidget);
      expect(find.text('CADT Cambodia'), findsAtLeastNWidgets(1));
      expect(find.text('Scholarship'), findsAtLeastNWidgets(1));
      expect(find.text('Apply Now'), findsOneWidget);
      expect(find.text('Opportunity Details'), findsOneWidget);
    });
  });
}
