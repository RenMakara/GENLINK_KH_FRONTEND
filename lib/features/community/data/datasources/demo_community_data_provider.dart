import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';

abstract final class DemoCommunityUsers {
  static const soknyEnat = (
    id: 'user_me',
    name: 'Sokny Enat',
    tag: '@soknyenat',
    university: 'ACLEDA University of Business',
    role: 'Student',
    avatar: 'assets/images/user_profile.png',
  );

  static const renMakara = (
    id: 'user_makara',
    name: 'Ren Makara',
    tag: '@renmakara',
    university: 'Royal University of Phnom Penh',
    role: 'CS Student',
    avatar: 'assets/images/ren_makara_profile.png',
  );

  static const hengChansela = (
    id: 'user_chansela',
    name: 'Heng Chansela',
    tag: '@hengchansela',
    university: 'Institute of Technology of Cambodia',
    role: 'Engineering Student',
    avatar: 'assets/images/heng_chansela_profile.png',
  );

  static const sreypichDara = (
    id: 'user_sreypich',
    name: 'Sreypich Dara',
    tag: '@sreypichdara',
    university: 'Cambodia Academy of Digital Technology',
    role: 'Software Engineering Student',
    avatar: 'assets/images/meimei_profile.png',
  );

  static const daraVicheka = (
    id: 'user_vicheka',
    name: 'Dara Vicheka',
    tag: '@daravicheka',
    university: 'Norton University',
    role: 'IT Student',
    avatar: 'assets/images/sum_sambo_profile.png',
  );
}

abstract final class DemoCommunityDataProvider {
  static bool isDemoEnabled = true;

  static bool forceDemoFeed = false;

  static List<CommunityPostModel> getDay15DemoPosts() {
    final suggestedEvents = getDay15SuggestedEvents();

    return [
      CommunityPostModel(
        id: 'post_day15_1',
        userId: DemoCommunityUsers.soknyEnat.id,
        authorName: DemoCommunityUsers.soknyEnat.name,
        authorTag: DemoCommunityUsers.soknyEnat.tag,
        authorAvatar: DemoCommunityUsers.soknyEnat.avatar,
        isVerified: false,
        timeAgo: '15m ago',
        content:
            'Today our Flutter workshop was amazing! Thank you to everyone who joined and shared their experience. 🚀 Building cross-platform mobile apps with Flutter & Cloud Infrastructure at ACLEDA University of Business! #Flutter #GenLinkKH #AUB #MobileDev',
        imageUrls: const [
          'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
        ],
        location: 'ACLEDA University of Business, Phnom Penh',
        likesCount: 48,
        commentsCount: 0,
        sharesCount: 4,
        isLiked: false,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.soknyEnat.university,
      ),

      CommunityPostModel(
        id: 'post_day15_2',
        userId: DemoCommunityUsers.renMakara.id,
        authorName: DemoCommunityUsers.renMakara.name,
        authorTag: DemoCommunityUsers.renMakara.tag,
        authorAvatar: DemoCommunityUsers.renMakara.avatar,
        isVerified: false,
        timeAgo: '45m ago',
        postType: 'DISCUSSION',
        discussionTitle:
            'What is the best way to structure a large Flutter application?',
        category: 'Technology',
        content:
            'As our student projects grow in scale, what architectural pattern has worked best for you? Should we prefer feature-first structure or layer-first with GetX? How do you organize domain repositories, controllers, and shared widgets cleanly? Let\'s discuss your thoughts! 💡',
        imageUrls: const [],
        location: 'Royal University of Phnom Penh (RUPP)',
        likesCount: 38,
        commentsCount: 0,
        sharesCount: 5,
        isLiked: false,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.renMakara.university,
      ),

      CommunityPostModel(
        id: 'post_day15_3',
        userId: DemoCommunityUsers.soknyEnat.id,
        authorName: DemoCommunityUsers.soknyEnat.name,
        authorTag: DemoCommunityUsers.soknyEnat.tag,
        authorAvatar: DemoCommunityUsers.soknyEnat.avatar,
        isVerified: false,
        timeAgo: '1h ago',
        postType: 'event',
        content:
            'Excited to announce our flagship campus workshop! Join us for a full day of hands-on Flutter development, reactive architecture, and real-time backend integration. Registration is now open to all students! 🎟️💻',
        attachedEvent: suggestedEvents.isNotEmpty ? suggestedEvents.first : null,
        imageUrls: const [],
        location: 'ACLEDA University of Business',
        likesCount: 65,
        commentsCount: 0,
        sharesCount: 9,
        isLiked: true,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.soknyEnat.university,
      ),

      CommunityPostModel(
        id: 'post_day15_4',
        userId: DemoCommunityUsers.hengChansela.id,
        authorName: DemoCommunityUsers.hengChansela.name,
        authorTag: DemoCommunityUsers.hengChansela.tag,
        authorAvatar: DemoCommunityUsers.hengChansela.avatar,
        isVerified: false,
        timeAgo: '2h ago',
        content:
            'Career Talk Series: Tech in Banking 🏦🎙️ We had inspiring discussions on digital payments, fintech microservices, and cyber resilience in modern banking with industry mentors at ITC. Huge thanks to all student engineers who participated! #TechInBanking #Fintech #ITC #CareerGrowth',
        imageUrls: const ['assets/images/heng_chansela_post.png'],
        location: 'Institute of Technology of Cambodia (ITC)',
        likesCount: 72,
        commentsCount: 0,
        sharesCount: 7,
        isLiked: false,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.hengChansela.university,
      ),

      CommunityPostModel(
        id: 'post_day15_5',
        userId: DemoCommunityUsers.sreypichDara.id,
        authorName: DemoCommunityUsers.sreypichDara.name,
        authorTag: DemoCommunityUsers.sreypichDara.tag,
        authorAvatar: DemoCommunityUsers.sreypichDara.avatar,
        isVerified: false,
        timeAgo: '3h ago',
        postType: 'DISCUSSION',
        discussionTitle:
            'How can students prepare for their first software engineering internship?',
        category: 'Career & Growth',
        content:
            'To senior students and tech mentors: what preparation strategies made the biggest difference when applying for junior roles? Should university students focus more on algorithmic problem solving, building GitHub portfolio projects, or learning teamwork with Git and CI/CD? Share your advice for juniors! 🌟',
        imageUrls: const [],
        location: 'Cambodia Academy of Digital Technology (CADT)',
        likesCount: 56,
        commentsCount: 0,
        sharesCount: 8,
        isLiked: false,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.sreypichDara.university,
      ),

      CommunityPostModel(
        id: 'post_day15_6',
        userId: DemoCommunityUsers.daraVicheka.id,
        authorName: DemoCommunityUsers.daraVicheka.name,
        authorTag: DemoCommunityUsers.daraVicheka.tag,
        authorAvatar: DemoCommunityUsers.daraVicheka.avatar,
        isVerified: false,
        timeAgo: '5h ago',
        content:
            'Successfully defended our Capstone final milestone today at Norton University! 🎉 Hard work, sleepless nights, and endless Git merge conflicts finally paid off. Huge thanks to our amazing project advisor and teammates! 🎓🚀 #Capstone #NortonUniversity #GraduationMilestone #Teamwork',
        imageUrls: const ['assets/images/authgate_project.png'],
        location: 'Norton University Campus',
        likesCount: 91,
        commentsCount: 0,
        sharesCount: 11,
        isLiked: false,
        isBookmarked: false,
        isOwner: false,
        community: DemoCommunityUsers.daraVicheka.university,
      ),
    ];
  }

  static List<EventModel> getDay15SuggestedEvents() {
    return [
      EventModel(
        id: 'ev_day15_1',
        title: 'Flutter Workshop 2026',
        subtitle: 'Build real-world mobile apps with Flutter from scratch.',
        organizerName: 'AUB Digital Academy',
        eventType: 'In person',
        location: 'ACLEDA University, Phnom Penh',
        dateString: '25 Jul 2026',
        timeString: '9:00 AM – 4:00 PM',
        description:
            'Hands-on workshop on clean architecture, reactive state management with GetX, and backend API integration.',
        category: 'Workshop',
        imageUrl:
            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&auto=format&fit=crop&q=80',
        attendeesCount: 120,
        attendeeAvatars: const [
          'assets/images/user_profile.png',
          'assets/images/heng_chansela_profile.png',
          'assets/images/ren_makara_profile.png',
        ],
      ),
      EventModel(
        id: 'ev_day15_2',
        title: 'AI in Everyday Life',
        subtitle: 'Exploring practical AI applications for students & creators.',
        organizerName: 'CADT Innovation Lab',
        eventType: 'Online',
        onlineLink: 'https://meet.google.com/genlink-ai-2026',
        location: '',
        dateString: '28 Jul 2026',
        timeString: '2:00 PM – 5:00 PM',
        description:
            'Discover how artificial intelligence is transforming productivity and campus workflows.',
        category: 'Seminar',
        imageUrl:
            'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=1200&auto=format&fit=crop&q=80',
        attendeesCount: 245,
        attendeeAvatars: const [
          'assets/images/user_profile.png',
          'assets/images/heng_chansela_profile.png',
        ],
      ),
    ];
  }

  static List<ForumTopicModel> getDay15TrendingDiscussions() {
    return [
      ForumTopicModel(
        id: 'disc_day15_1',
        authorId: DemoCommunityUsers.soknyEnat.id,
        title: 'Best practices for GetX state management in Flutter Community App',
        authorName: DemoCommunityUsers.soknyEnat.name,
        authorAvatar: DemoCommunityUsers.soknyEnat.avatar,
        timeAgo: '2h ago',
        category: 'Technology',
        content:
            'When structuring large Flutter apps with GetX, prefer domain separation, avoid calling Get.put inside build methods, and use bindings for deterministic lifecycle management.',
        repliesCount: 24,
        upvotes: 89,
        isLiked: false,
        isOwner: false,
      ),
      ForumTopicModel(
        id: 'disc_day15_2',
        authorId: DemoCommunityUsers.hengChansela.id,
        title: 'Study group for CADT Data Structures and Algorithms exam next week',
        authorName: DemoCommunityUsers.hengChansela.name,
        authorAvatar: DemoCommunityUsers.hengChansela.avatar,
        timeAgo: '5h ago',
        category: 'Study & Education',
        content:
            'We are organizing an online and on-campus study session for DSA. Topics include Dynamic Programming, Graph Traversals, and Complexity Analysis.',
        repliesCount: 31,
        upvotes: 67,
        isLiked: false,
        isOwner: false,
      ),
    ];
  }
}
