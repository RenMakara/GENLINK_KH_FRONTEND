import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';

void main() {
  group('EventModel Backend Synchronization Tests', () {
    test('1. Normal In-Person Event from Backend EventResponse JSON', () {
      final json = {
        'eventId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'organizerId': '8b9e6f21-7291-4c12-9844-0192837465ab',
        'title': 'Flutter Workshop',
        'description': 'Intro to Flutter',
        'category': 'WORKSHOP',
        'coverImageUrl': 'https://example.com/cover.jpg',
        'startDateTime': '2026-10-01T14:00:00',
        'endDateTime': '2026-10-01T16:00:00',
        'mode': 'IN_PERSON',
        'meetingUrl': null,
        'locationName': 'ACLEDA University of Business',
        'latitude': 11.5564,
        'longitude': 104.9282,
        'attendeeLimit': 50,
        'attendeeCount': 12,
        'status': 'PUBLISHED',
        'language': 'ENGLISH',
        'paid': false,
        'price': null,
        'currency': null,
        'myRsvpStatus': null,
        'full': false,
        'createdAt': '2026-09-08T10:00:00Z',
      };

      final event = EventModel.fromJson(json);

      expect(event.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(event.organizerId, '8b9e6f21-7291-4c12-9844-0192837465ab');
      expect(event.title, 'Flutter Workshop');
      expect(event.description, 'Intro to Flutter');
      expect(event.category, 'WORKSHOP');
      expect(event.imageUrl, 'https://example.com/cover.jpg');
      expect(event.startDateTime, DateTime.parse('2026-10-01T14:00:00'));
      expect(event.endDateTime, DateTime.parse('2026-10-01T16:00:00'));
      expect(event.mode, 'IN_PERSON');
      expect(event.eventMode, EventMode.inPerson);
      expect(event.isInPerson, isTrue);
      expect(event.isOnline, isFalse);
      expect(event.locationName, 'ACLEDA University of Business');
      expect(event.location, 'ACLEDA University of Business');
      expect(event.meetingUrl, isNull);
      expect(event.latitude, 11.5564);
      expect(event.longitude, 104.9282);
      expect(event.attendeeLimit, 50);
      expect(event.attendeesCount, 12);
      expect(event.status, 'PUBLISHED');
      expect(event.language, 'ENGLISH');
      expect(event.isPaid, isFalse);
      expect(event.price, isNull);
      expect(event.currency, isNull);
      expect(event.myRsvpStatus, isNull);
      expect(event.isRsvped, isFalse);
      expect(event.isFull, isFalse);
      expect(event.formattedPrice, 'Free');
      expect(event.effectiveLocation, 'ACLEDA University of Business');
      expect(event.dateString, isNotEmpty);
      expect(event.timeString, isNotEmpty);
    });

    test('1b. Event with nested backend organizer AuthorSummary', () {
      final json = {
        'eventId': 'event-nested-org',
        'organizer': {
          'id': 'org-uuid-123',
          'fullName': 'Sokny Enat',
          'username': 'enat',
          'avatarUrl': 'https://example.com/avatar.png',
        },
        'title': 'Tech Talk',
      };

      final event = EventModel.fromJson(json);

      expect(event.organizerId, 'org-uuid-123');
      expect(event.organizerName, 'Sokny Enat');
    });

    test('2. Online Event with meetingUrl', () {
      final json = {
        'eventId': 'event-online-1',
        'title': 'Online Dev Meetup',
        'startDateTime': '2026-10-05T19:00:00',
        'endDateTime': '2026-10-05T21:00:00',
        'mode': 'ONLINE',
        'meetingUrl': 'https://meet.google.com/abc-defg-hij',
        'locationName': null,
        'paid': false,
      };

      final event = EventModel.fromJson(json);

      expect(event.isOnline, isTrue);
      expect(event.isInPerson, isFalse);
      expect(event.eventMode, EventMode.online);
      expect(event.meetingUrl, 'https://meet.google.com/abc-defg-hij');
      // A backend response that contains only meetingUrl must not be copied
      // into the legacy/public onlineLink or location fields.
      expect(event.onlineLink, isEmpty);
      expect(event.effectiveLocation, isEmpty);
      expect(event.eventType, 'Online');
    });

    test('3. Missing startDateTime and endDateTime (null-safe)', () {
      final json = {'id': 'fallback-event', 'title': 'TBD Event'};

      final event = EventModel.fromJson(json);

      expect(event.id, 'fallback-event');
      expect(event.startDateTime, isNull);
      expect(event.endDateTime, isNull);
      expect(event.formattedStartDate, '');
      expect(event.formattedEndDate, '');
      expect(event.formattedDateRange, '');
    });

    test('4. Legacy dateTime field fallback', () {
      final json = {
        'id': 'legacy-1',
        'title': 'Legacy Schedule',
        'dateTime': '2026-11-15T09:30:00',
      };

      final event = EventModel.fromJson(json);

      expect(event.startDateTime, DateTime.parse('2026-11-15T09:30:00'));
      expect(event.formattedStartDate, contains('2026'));
      expect(event.formattedStartTime, contains('9:30'));
    });

    test('5. Null meetingUrl and Null locationName', () {
      final json = {
        'eventId': 'event-no-loc',
        'title': 'Undecided Venue',
        'meetingUrl': null,
        'locationName': null,
      };

      final event = EventModel.fromJson(json);

      expect(event.meetingUrl, isNull);
      expect(event.locationName, isNull);
      expect(event.location, '');
      expect(event.onlineLink, '');
      expect(event.effectiveLocation, '');
    });

    test('6. Coordinates parsing (Missing, Integer, Decimal, String)', () {
      final jsonMissing = {'eventId': 'e1', 'title': 'E1'};
      final eMissing = EventModel.fromJson(jsonMissing);
      expect(eMissing.latitude, isNull);
      expect(eMissing.longitude, isNull);

      final jsonInt = {
        'eventId': 'e2',
        'title': 'E2',
        'latitude': 11,
        'longitude': 104,
      };
      final eInt = EventModel.fromJson(jsonInt);
      expect(eInt.latitude, 11.0);
      expect(eInt.longitude, 104.0);

      final jsonDecimal = {
        'eventId': 'e3',
        'title': 'E3',
        'latitude': 11.5564,
        'longitude': 104.9282,
      };
      final eDecimal = EventModel.fromJson(jsonDecimal);
      expect(eDecimal.latitude, 11.5564);
      expect(eDecimal.longitude, 104.9282);

      final jsonString = {
        'eventId': 'e4',
        'title': 'E4',
        'latitude': '11.5564',
        'longitude': '104.9282',
      };
      final eString = EventModel.fromJson(jsonString);
      expect(eString.latitude, 11.5564);
      expect(eString.longitude, 104.9282);

      final jsonInvalid = {
        'eventId': 'e5',
        'title': 'E5',
        'latitude': 'invalid-lat',
        'longitude': 'invalid-lng',
      };
      final eInvalid = EventModel.fromJson(jsonInvalid);
      expect(eInvalid.latitude, isNull);
      expect(eInvalid.longitude, isNull);
    });

    test('7. Free Event presentation', () {
      final json = {
        'eventId': 'free-1',
        'title': 'Free Event',
        'paid': false,
        'price': null,
        'currency': null,
      };

      final event = EventModel.fromJson(json);

      expect(event.isPaid, isFalse);
      expect(event.price, isNull);
      expect(event.currency, isNull);
      expect(event.formattedPrice, 'Free');
    });

    test('8. Paid USD Event presentation', () {
      final json = {
        'eventId': 'usd-1',
        'title': 'USD Conference',
        'paid': true,
        'price': 15.50,
        'currency': 'USD',
      };

      final event = EventModel.fromJson(json);

      expect(event.isPaid, isTrue);
      expect(event.price, 15.50);
      expect(event.currency, 'USD');
      expect(event.formattedPrice, '\$15.50 USD');
    });

    test('9. Paid KHR Event presentation', () {
      final json = {
        'eventId': 'khr-1',
        'title': 'KHR Hackathon',
        'paid': true,
        'price': 20000,
        'currency': 'KHR',
      };

      final event = EventModel.fromJson(json);

      expect(event.isPaid, isTrue);
      expect(event.price, 20000.0);
      expect(event.priceKhr, 20000.0);
      expect(event.currency, 'KHR');
      expect(event.formattedPrice, '20,000 ៛');
    });

    test('10. Null currency handling on paid event', () {
      final json = {
        'eventId': 'null-curr',
        'title': 'Event without currency',
        'paid': true,
        'price': 10.0,
        'currency': null,
      };

      final event = EventModel.fromJson(json);

      expect(event.isPaid, isTrue);
      expect(event.currency, isNull);
      expect(event.formattedPrice, '\$10.00');
    });

    test('11. Unknown / future event mode', () {
      final json = {
        'eventId': 'future-mode',
        'title': 'Hybrid Metaverse Event',
        'mode': 'METAVERSE_HYBRID',
      };

      final event = EventModel.fromJson(json);

      expect(event.mode, 'METAVERSE_HYBRID');
      expect(event.eventMode, EventMode.unknown);
      expect(event.isOnline, isFalse);
      expect(event.isInPerson, isFalse);
    });

    test('12. Unknown/missing optional fields do not crash', () {
      final json = <String, dynamic>{};

      final event = EventModel.fromJson(json);

      expect(event.id, '');
      expect(event.title, '');
      expect(event.isPaid, isFalse);
      expect(event.attendeesCount, 0);
      expect(event.isRsvped, isFalse);
      expect(event.isFull, isFalse);
    });

    test('13. My RSVP status parsing', () {
      final jsonJoined = {
        'eventId': 'e-joined',
        'title': 'Joined Event',
        'myRsvpStatus': 'JOINED',
      };
      expect(EventModel.fromJson(jsonJoined).isRsvped, isTrue);
      expect(EventModel.fromJson(jsonJoined).myRsvpStatus, 'JOINED');

      final jsonCancelled = {
        'eventId': 'e-cancelled',
        'title': 'Cancelled Event',
        'myRsvpStatus': 'CANCELLED',
      };
      expect(EventModel.fromJson(jsonCancelled).isRsvped, isFalse);
      expect(EventModel.fromJson(jsonCancelled).myRsvpStatus, 'CANCELLED');
    });

    test('14. Full capacity flag', () {
      final jsonFull = {
        'eventId': 'full-event',
        'title': 'Sold Out Event',
        'full': true,
      };
      expect(EventModel.fromJson(jsonFull).isFull, isTrue);
    });

    test('15. EventModel.toJson serialization', () {
      final event = EventModel(
        id: 'ev-123',
        title: 'Tech Fest',
        organizerName: 'CADT',
        organizerId: 'org-456',
        dateString: 'Oct 1, 2026',
        timeString: '2:00 PM',
        startDateTime: DateTime.parse('2026-10-01T14:00:00'),
        endDateTime: DateTime.parse('2026-10-01T16:00:00'),
        mode: 'IN_PERSON',
        locationName: 'Campus Hall',
        latitude: 11.55,
        longitude: 104.92,
        attendeeLimit: 100,
        attendeesCount: 25,
        isPaid: true,
        price: 5.00,
        currency: 'USD',
        myRsvpStatus: 'JOINED',
        isFull: false,
      );

      final json = event.toJson();

      expect(json['eventId'], 'ev-123');
      expect(json['title'], 'Tech Fest');
      expect(json['organizerId'], 'org-456');
      expect(json['startDateTime'], contains('2026-10-01T14:00:00'));
      expect(json['endDateTime'], contains('2026-10-01T16:00:00'));
      expect(json['mode'], 'IN_PERSON');
      expect(json['locationName'], 'Campus Hall');
      expect(json['latitude'], 11.55);
      expect(json['longitude'], 104.92);
      expect(json['attendeeLimit'], 100);
      expect(json['attendeeCount'], 25);
      expect(json['paid'], isTrue);
      expect(json['price'], 5.00);
      expect(json['currency'], 'USD');
      expect(json['myRsvpStatus'], 'JOINED');
      expect(json['full'], isFalse);
    });

    test('16. EventModel.copyWith preserves and overrides', () {
      final original = EventModel(
        id: 'orig',
        title: 'Original Title',
        organizerName: 'Organizer',
        dateString: 'Oct 1',
        timeString: '10:00 AM',
        isPaid: false,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isPaid: true,
        price: 10.0,
        currency: 'USD',
      );

      expect(updated.id, 'orig');
      expect(updated.title, 'Updated Title');
      expect(updated.isPaid, isTrue);
      expect(updated.price, 10.0);
      expect(updated.currency, 'USD');
    });
  });

  group('EventCreateRequest Serializer Tests', () {
    test('Serializes paid event with exact backend keys', () {
      final req = EventCreateRequest(
        title: 'KHR Paid Workshop',
        description: 'Paid event example in Khmer riel',
        category: 'WORKSHOP',
        coverImageUrl: null,
        startDateTime: DateTime.parse('2026-10-02T14:00:00'),
        endDateTime: DateTime.parse('2026-10-02T16:00:00'),
        mode: 'IN_PERSON',
        meetingUrl: null,
        locationName: 'ACLEDA University',
        latitude: 11.5564,
        longitude: 104.9282,
        attendeeLimit: 50,
        status: 'PUBLISHED',
        language: 'ENGLISH',
        paid: true,
        price: 5000,
        currency: 'KHR',
      );

      final json = req.toJson();

      expect(json['title'], 'KHR Paid Workshop');
      expect(json['description'], 'Paid event example in Khmer riel');
      expect(json['category'], 'WORKSHOP');
      expect(json['coverImageUrl'], isNull);
      expect(json['startDateTime'], contains('2026-10-02T14:00:00'));
      expect(json['endDateTime'], contains('2026-10-02T16:00:00'));
      expect(json['mode'], 'IN_PERSON');
      expect(json['meetingUrl'], isNull);
      expect(json['locationName'], 'ACLEDA University');
      expect(json['latitude'], 11.5564);
      expect(json['longitude'], 104.9282);
      expect(json['attendeeLimit'], 50);
      expect(json['status'], 'PUBLISHED');
      expect(json['language'], 'ENGLISH');
      expect(json['paid'], isTrue);
      expect(json['price'], 5000.0);
      expect(json['currency'], 'KHR');
    });

    test('Serializes online free event with meetingUrl', () {
      final req = EventCreateRequest(
        title: 'Webinar',
        startDateTime: DateTime.parse('2026-10-03T18:00:00'),
        endDateTime: DateTime.parse('2026-10-03T20:00:00'),
        mode: 'ONLINE',
        meetingUrl: 'https://meet.google.com/xyz',
        paid: false,
      );

      final json = req.toJson();

      expect(json['mode'], 'ONLINE');
      expect(json['meetingUrl'], 'https://meet.google.com/xyz');
      expect(json['paid'], isFalse);
      expect(json['price'], isNull);
      expect(json['currency'], isNull);
    });
  });

  group('EventRegistrationRequest Serializer Tests', () {
    test('Serializes registration form with exact backend keys', () {
      const reg = EventRegistrationRequest(
        fullName: 'Sokny Enat',
        email: 'enat@example.com',
        phoneNumber: '012345678',
        university: 'ACLEDA University of Business',
        faculty: 'Computer Science',
        studyYear: 'Year 3',
        termsAccepted: true,
      );

      final json = reg.toJson();

      expect(json['fullName'], 'Sokny Enat');
      expect(json['email'], 'enat@example.com');
      expect(json['phoneNumber'], '012345678');
      expect(json['university'], 'ACLEDA University of Business');
      expect(json['faculty'], 'Computer Science');
      expect(json['studyYear'], 'Year 3');
      expect(json['termsAccepted'], isTrue);

      final parsed = EventRegistrationRequest.fromJson(json);
      expect(parsed.fullName, 'Sokny Enat');
      expect(parsed.termsAccepted, isTrue);
    });

    test('Allows an omitted studyYear for a non-student request', () {
      const reg = EventRegistrationRequest(
        fullName: 'Sokny Enat',
        email: 'enat@example.com',
        phoneNumber: '012345678',
        university: 'ACLEDA University of Business',
        faculty: 'Computer Science',
      );

      expect(reg.studyYear, isNull);
      expect(reg.toJson()['studyYear'], isNull);
      expect(EventRegistrationRequest.fromJson(reg.toJson()).studyYear, isNull);
    });
  });

  group('Event state and access mapping', () {
    final future = DateTime.now().add(const Duration(days: 2));

    test('Only published future events are RSVP eligible', () {
      EventModel event(String status, {DateTime? start}) => EventModel(
        id: status,
        title: status,
        organizerId: 'owner-1',
        status: status,
        startDateTime: start ?? future,
      );

      expect(event('PUBLISHED').isRsvpEligible, isTrue);
      expect(event('DRAFT').isRsvpEligible, isFalse);
      expect(event('CANCELLED').isRsvpEligible, isFalse);
      expect(event('COMPLETED').isRsvpEligible, isFalse);
      expect(
        event(
          'PUBLISHED',
          start: DateTime.now().subtract(const Duration(minutes: 1)),
        ).isRsvpEligible,
        isFalse,
      );
    });

    test('Meeting access requires owner or JOINED RSVP', () {
      final event = EventModel(
        id: 'event-1',
        title: 'Online',
        organizerId: 'owner-1',
        meetingUrl: 'https://meet.example/event-1',
        myRsvpStatus: 'JOINED',
      );
      expect(event.canAccessMeetingFor('owner-1'), isTrue);
      expect(event.canAccessMeetingFor('attendee-1'), isTrue);
      expect(
        event
            .copyWith(myRsvpStatus: 'CANCELLED', isRsvped: false)
            .canAccessMeetingFor('attendee-1'),
        isFalse,
      );
    });
  });

  group('RsvpResponseModel Deserializer Tests', () {
    test('Parses simulated paid RSVP response', () {
      final json = {
        'eventId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'status': 'JOINED',
        'attendeeCount': 6,
        'xpAwarded': 10,
        'amountPaid': 5000.0,
        'simulatedPayment': true,
      };

      final res = RsvpResponseModel.fromJson(json);

      expect(res.eventId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(res.status, 'JOINED');
      expect(res.attendeeCount, 6);
      expect(res.xpAwarded, 10);
      expect(res.amountPaid, 5000.0);
      expect(res.simulatedPayment, isTrue);
    });
  });
}
