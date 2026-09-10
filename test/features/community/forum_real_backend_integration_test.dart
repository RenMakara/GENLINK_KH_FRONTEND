import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forum Real Backend DTO Contract & Deserialization', () {
    test('ForumTopicModel deserializes backend DiscussionResponse JSON schema accurately', () {
      final backendJson = {
        'discussionId': '99bb3c80-4927-4c7b-b519-216ebbe50450',
        'author': {
          'userId': 'usr_real_001',
          'fullName': 'Sokny Enat',
          'username': 'sokny',
          'avatarUrl': 'https://storage.campuslink.kh/avatar.png',
        },
        'title': 'ការណែនាំអំពី Architecture សម្រាប់ GenLink',
        'content': 'សូមស្វាគមន៍មកកាន់ការពិភាក្សាអំពី clean architecture ជាមួយ Flutter.',
        'category': 'Technology',
        'anonymous': false,
        'language': 'KHMER',
        'reactionCount': 42,
        'commentCount': 7,
        'reactedByMe': true,
        'mine': true,
        'createdAt': '2026-09-09T17:00:00Z',
      };

      final model = ForumTopicModel.fromJson(backendJson);

      expect(model.id, '99bb3c80-4927-4c7b-b519-216ebbe50450');
      expect(model.authorId, 'usr_real_001');
      expect(model.authorName, 'Sokny Enat');
      expect(model.authorAvatar, 'https://storage.campuslink.kh/avatar.png');
      expect(model.title, 'ការណែនាំអំពី Architecture សម្រាប់ GenLink');
      expect(model.content, 'សូមស្វាគមន៍មកកាន់ការពិភាក្សាអំពី clean architecture ជាមួយ Flutter.');
      expect(model.category, 'Technology');
      expect(model.upvotes, 42);
      expect(model.repliesCount, 7);
      expect(model.isLiked, isTrue);
      expect(model.isOwner, isTrue);
    });

    test('CommentModel deserializes backend CommentResponse JSON schema accurately', () {
      final backendCommentJson = {
        'commentId': 'cmt_real_1234',
        'discussionId': '99bb3c80-4927-4c7b-b519-216ebbe50450',
        'author': {
          'userId': 'usr_real_002',
          'fullName': 'Bopha Pich',
          'username': 'bopha',
          'avatarUrl': 'https://storage.campuslink.kh/bopha.png',
        },
        'content': 'គំនិតល្អណាស់បង!',
        'likeCount': 5,
        'likedByMe': true,
        'parentCommentId': null,
        'mine': false,
        'createdAt': '2026-09-09T17:05:00Z',
      };

      final comment = CommentModel.fromJson(backendCommentJson);

      expect(comment.id, 'cmt_real_1234');
      expect(comment.postId, '99bb3c80-4927-4c7b-b519-216ebbe50450');
      expect(comment.userId, 'usr_real_002');
      expect(comment.userName, 'Bopha Pich');
      expect(comment.userAvatar, 'https://storage.campuslink.kh/bopha.png');
      expect(comment.text, 'គំនិតល្អណាស់បង!');
      expect(comment.likesCount, 5);
      expect(comment.isLiked, isTrue);
      expect(comment.isOwner, isFalse);
    });
  });

  group('Forum Ownership & Authorization Rules', () {
    test('checkIsOwner returns true when backend confirms mine: true', () {
      final topic = ForumTopicModel(
        id: 'disc_1',
        authorId: 'usr_real_001',
        title: 'Title',
        authorName: 'Author',
        category: 'Technology',
        content: 'Content',
        timeAgo: 'Just now',
        isOwner: true,
      );

      // Server-authoritative ownership is respected
      expect(topic.checkIsOwner(null), isTrue);
      expect(topic.checkIsOwner(''), isTrue);
      expect(topic.checkIsOwner('usr_real_001'), isTrue);
    });

    test('checkIsOwner returns true when authenticated user matches authorId', () {
      final topic = ForumTopicModel(
        id: 'disc_1',
        authorId: 'usr_real_001',
        title: 'Title',
        authorName: 'Author',
        category: 'Technology',
        content: 'Content',
        timeAgo: 'Just now',
        isOwner: false,
      );

      expect(topic.checkIsOwner('usr_real_001'), isTrue);
      expect(topic.checkIsOwner('usr_real_002'), isFalse);
    });

    test('checkIsOwner denies permission when user IDs do not match and not owner', () {
      final topic = ForumTopicModel(
        id: 'disc_1',
        authorId: 'usr_real_001',
        title: 'Title',
        authorName: 'Author',
        category: 'Technology',
        content: 'Content',
        timeAgo: 'Just now',
        isOwner: false,
      );

      expect(topic.checkIsOwner('different_user'), isFalse);
    });
  });

  group('CommunityController Discussion & Comment Flow with Rollback on Error', () {
    late CommunityController controller;
    late _MockCommunityRepository mockRepo;

    setUp(() {
      mockRepo = _MockCommunityRepository();
      controller = CommunityController(repository: mockRepo);
    });

    test('addDiscussion inserts created discussion to forumLatestDiscussions', () async {
      final created = await controller.addDiscussion(
        title: 'ការបង្កើត Discussion ថ្មី',
        content: 'មាតិកាថ្មី',
        category: 'Technology',
      );

      expect(created.title, 'ការបង្កើត Discussion ថ្មី');
      expect(controller.forumLatestDiscussions.length, 1);
      expect(controller.forumLatestDiscussions.first.id, created.id);
    });

    test('toggleDiscussionLike performs optimistic update and rolls back on failure', () async {
      final initial = ForumTopicModel(
        id: 'disc_err_1',
        title: 'Test Discussion',
        authorName: 'Tester',
        category: 'Career',
        content: 'Testing error rollback',
        timeAgo: 'Just now',
        upvotes: 10,
        isLiked: false,
      );
      controller.forumLatestDiscussions.add(initial);

      // Set repository to fail
      mockRepo.shouldFailReaction = true;

      final result = await controller.toggleDiscussionLike('disc_err_1');

      expect(result, isFalse);
      // State should be rolled back
      final item = controller.forumLatestDiscussions.first;
      expect(item.isLiked, isFalse);
      expect(item.upvotes, 10);
    });

    test('toggleDiscussionCommentLike performs optimistic update and rolls back on failure', () async {
      final comment = CommentModel(
        id: 'cmt_err_1',
        postId: 'disc_1',
        userId: 'usr_1',
        userName: 'User 1',
        userAvatar: '',
        text: 'A comment',
        timeAgo: 'Just now',
        likesCount: 3,
        isLiked: false,
      );
      controller.discussionComments['disc_1'] = [comment];

      // Set repository to fail
      mockRepo.shouldFailCommentReaction = true;

      final result = await controller.toggleDiscussionCommentLike('disc_1', 'cmt_err_1');

      expect(result, isFalse);
      final c = controller.discussionComments['disc_1']!.first;
      expect(c.isLiked, isFalse);
      expect(c.likesCount, 3);
    });

    test('deleteDiscussion removes discussion from list on success', () async {
      final topic = ForumTopicModel(
        id: 'disc_del_1',
        title: 'To Delete',
        authorName: 'Tester',
        category: 'Career',
        content: 'Delete me',
        timeAgo: 'Just now',
      );
      controller.forumLatestDiscussions.add(topic);

      final success = await controller.deleteDiscussion('disc_del_1');

      expect(success, isTrue);
      expect(controller.forumLatestDiscussions.any((d) => d.id == 'disc_del_1'), isFalse);
    });

    test('deleteDiscussionComment removes comment and decrements repliesCount', () async {
      final topic = ForumTopicModel(
        id: 'disc_c_1',
        title: 'Discussion with comments',
        authorName: 'Tester',
        category: 'Technology',
        content: 'Content',
        timeAgo: 'Just now',
        repliesCount: 2,
      );
      controller.forumLatestDiscussions.add(topic);

      final c1 = CommentModel(
        id: 'c_1',
        postId: 'disc_c_1',
        userId: 'u_1',
        userName: 'U1',
        userAvatar: '',
        text: 'comment 1',
        timeAgo: '1m',
      );
      final c2 = CommentModel(
        id: 'c_2',
        postId: 'disc_c_1',
        userId: 'u_2',
        userName: 'U2',
        userAvatar: '',
        text: 'comment 2',
        timeAgo: '1m',
      );
      controller.discussionComments['disc_c_1'] = [c1, c2];

      final success = await controller.deleteDiscussionComment('disc_c_1', 'c_1');

      expect(success, isTrue);
      expect(controller.discussionComments['disc_c_1']!.length, 1);
      expect(controller.discussionComments['disc_c_1']!.first.id, 'c_2');
      expect(controller.forumLatestDiscussions.first.repliesCount, 1);
    });
  });
}

class _MockCommunityRepository extends Fake implements CommunityRepository {
  bool shouldFailReaction = false;
  bool shouldFailCommentReaction = false;

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    return ForumTopicModel(
      id: 'mock_created_id_1',
      title: title,
      authorName: 'Current User',
      category: category,
      content: content,
      timeAgo: 'Just now',
      isOwner: true,
    );
  }

  @override
  Future<bool> toggleDiscussionLike(String discussionId, {bool isCurrentlyLiked = false}) async {
    if (shouldFailReaction) {
      throw AppError(message: 'Network error', errorCode: 'NETWORK_ERROR');
    }
    return true;
  }

  @override
  Future<bool> toggleDiscussionCommentLike(String commentId, {required bool isCurrentlyLiked}) async {
    if (shouldFailCommentReaction) {
      throw AppError(message: 'Network error', errorCode: 'NETWORK_ERROR');
    }
    return true;
  }

  @override
  Future<bool> deleteDiscussion(String discussionId) async => true;

  @override
  Future<bool> deleteDiscussionComment(String commentId) async => true;

  @override
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => [];

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId, {int page = 1, int limit = 20}) async => [];
}
