/// API endpoint registry.
///
/// All backend contract paths live here. Feature modules reference these
/// constants instead of hardcoding URL strings.
///
/// Paths are verified against the Spring Boot controllers, not the draft
/// API docs — profile lives under `/profile/*`, not `/users/me/*`.
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  static const _base = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const login = '$_base/auth/login';
  static const register = '$_base/auth/register';
  static const googleLogin = '$_base/auth/google';
  static const verifyEmail = '$_base/auth/verify-email';
  static const verifyOtp = '$_base/auth/verify-otp';
  static const resendOtp = '$_base/auth/resend-otp';
  static const resendVerificationOtp = '$_base/auth/resend-verification-otp';
  static const forgotPassword = '$_base/auth/forgot-password';
  static const verifyResetOtp = '$_base/auth/verify-reset-otp';
  static const resetPassword = '$_base/auth/reset-password';
  static const refreshToken = '$_base/auth/refresh-token';
  static const me = '$_base/auth/me';
  static const logout = '$_base/auth/logout';

  // ── Media ─────────────────────────────────────────────────────────────
  //
  // Only presign/confirm/url/delete are ours. The upload itself PUTs to the
  // absolute `uploadUrl` returned by presign, which points at the storage
  // provider — never at this API.
  static const mediaPresign = '$_base/media/presign';
  static const mediaConfirm = '$_base/media/confirm';
  static String mediaUrl(String mediaId) => '$_base/media/$mediaId/url';
  static String mediaItem(String mediaId) => '$_base/media/$mediaId';

  // ── Profile ───────────────────────────────────────────────────────────
  static const profileMe = '$_base/profile/me';
  static const profileAvatar = '$_base/profile/avatar';

  /// Public profile is keyed by username, nested under `/public/` so it can
  /// never collide with the sibling literal routes.
  static String publicProfile(String username) =>
      '$_base/profile/public/$username';

  // ── Settings ──────────────────────────────────────────────────────────
  static const profileSettings = '$_base/profile/settings';

  // ── Interests ─────────────────────────────────────────────────────────
  /// Full catalog, names already resolved to the caller's language.
  static const interestCatalog = '$_base/interests';
  static const profileInterests = '$_base/profile/interests';

  // ── Portfolio ─────────────────────────────────────────────────────────
  static const profilePortfolio = '$_base/profile/portfolio';

  static String profilePortfolioItem(String portfolioId) =>
      '$_base/profile/portfolio/$portfolioId';

  // ── Social links ──────────────────────────────────────────────────────
  /// Upsert by platform: PUT replaces the existing link for that platform.
  static const profileSocialLinks = '$_base/profile/social-links';

  static String profileSocialLink(String platform) =>
      '$_base/profile/social-links/$platform';

  // ── Saved items ───────────────────────────────────────────────────────
  static const profileSaved = '$_base/profile/saved';
  static const profileSavedCheck = '$_base/profile/saved/check';

  static String profileSavedItem(String itemType, String itemId) =>
      '$_base/profile/saved/$itemType/$itemId';

  // ── Badges / achievements ─────────────────────────────────────────────
  /// Full catalog with an `earned` flag per badge — this is what the
  /// profile's achievements row renders (earned ones plus locked ones).
  static const badges = '$_base/entertainment/badges';
  static const myBadges = '$_base/entertainment/badges/mine';

  // ── Mobile BFF ────────────────────────────────────────────────────────
  static const mobileHome = '$_base/mobile/home';
  static const mobileProfileSummary = '$_base/mobile/profile-summary';
  static const mobileFinanceDashboard = '$_base/mobile/finance-dashboard';
  static const mobileProductivityDashboard =
      '$_base/mobile/productivity-dashboard';

  // ── Productivity ──────────────────────────────────────────────────────
  static const habits = '$_base/productivity/habits';
  static String habit(String habitId) => '$_base/productivity/habits/$habitId';
  static String habitCheckIn(String habitId) =>
      '$_base/productivity/habits/$habitId/check-in';

  static const tasks = '$_base/productivity/tasks';
  static String task(String taskId) => '$_base/productivity/tasks/$taskId';
  static String taskComplete(String taskId) =>
      '$_base/productivity/tasks/$taskId/complete';

  static const goals = '$_base/productivity/goals';
  static String goal(String goalId) => '$_base/productivity/goals/$goalId';
  static String goalMilestones(String goalId) =>
      '$_base/productivity/goals/$goalId/milestones';
  static String goalMilestoneComplete(String goalId, String milestoneId) =>
      '$_base/productivity/goals/$goalId/milestones/$milestoneId/complete';
  static String goalMilestone(String goalId, String milestoneId) =>
      '$_base/productivity/goals/$goalId/milestones/$milestoneId';

  static const focusSessions = '$_base/productivity/focus-sessions';
  static const focusSessionStart = '$_base/productivity/focus-sessions/start';
  static String focusSessionComplete(String sessionId) =>
      '$_base/productivity/focus-sessions/$sessionId/complete';
  static const focusSessionStats = '$_base/productivity/focus-sessions/stats';

  static const motivation = '$_base/productivity/motivation';
  static const savedMotivation = '$_base/productivity/motivation/saved';
  static String motivationItem(String motivationId) =>
      '$_base/productivity/motivation/$motivationId';
  static String motivationSave(String motivationId) =>
      '$_base/productivity/motivation/$motivationId/save';

  // ── Finance ──────────────────────────────────────────────────────────
  static const financeWallet = '$_base/finance/wallet';
  static const financeWalletTopUp = '$_base/finance/wallet/top-up';
  static const financeWalletPay = '$_base/finance/wallet/pay';
  static const financeWalletTransactions = '$_base/finance/wallet/transactions';

  static const financeIncomes = '$_base/finance/incomes';
  static const financeCashFlow = '$_base/finance/incomes/cash-flow';

  static const financeExpenses = '$_base/finance/expenses';
  static const financeExpenseSummary = '$_base/finance/expenses/summary';

  static const financeBudgets = '$_base/finance/budgets';
  static const financeBudgetCurrent = '$_base/finance/budgets/current';

  static const financeSavings = '$_base/finance/savings';

  static String financeIncome(String incomeId) =>
      '$_base/finance/incomes/$incomeId';

  static String financeExpense(String expenseId) =>
      '$_base/finance/expenses/$expenseId';

  static String financeBudget(String budgetId) =>
      '$_base/finance/budgets/$budgetId';

  static String financeSaving(String savingGoalId) =>
      '$_base/finance/savings/$savingGoalId';

  static String financeSavingDeposits(String savingGoalId) =>
      '$_base/finance/savings/$savingGoalId/deposits';

  // ── Finance learning ────────────────────────────────────────────────
  static const financeLearningDashboard = '$_base/finance/literacy/dashboard';
  static const financeLearningLessons = '$_base/finance/literacy/lessons';

  static String financeLearningLesson(String lessonId) =>
      '$_base/finance/literacy/lessons/$lessonId';

  static String financeLearningComplete(String lessonId) =>
      '$_base/finance/literacy/lessons/$lessonId/complete';

  static String financeLearningQuiz(String lessonId) =>
      '$_base/finance/literacy/lessons/$lessonId/quiz';

  static String financeLearningQuizSubmit(String lessonId) =>
      '$_base/finance/literacy/lessons/$lessonId/quiz/submit';

  // ── Community ─────────────────────────────────────────────────────────
  static const communityFeed = '$_base/community/posts/feed';
  static const communityPosts = '$_base/community/posts';
  static const communityPoll = '$_base/community/posts/poll';

  static String communityPollVote(String postId) =>
      '$_base/community/posts/$postId/poll/vote';

  static String communityPostDetail(String postId) =>
      '$_base/community/posts/$postId';

  static String communityPostLike(String postId) =>
      '$_base/community/posts/$postId/like';

  static String communityPostLikes(String postId) =>
      '$_base/community/posts/$postId/likes';

  static String communityPostBookmark(String postId) =>
      '$_base/community/posts/$postId/bookmark';

  static String communityPostRepost(String postId) =>
      '$_base/community/posts/$postId/repost';

  static String communityPostReport(String postId) =>
      '$_base/community/posts/$postId/report';

  static String communityPostComments(String postId) =>
      '$_base/community/posts/$postId/comments';

  static String communityComment(String commentId) =>
      '$_base/community/comments/$commentId';

  static String communityCommentReplies(String commentId) =>
      '$_base/community/comments/$commentId/replies';

  static String communityFollowUser(String userId) =>
      '$_base/community/users/$userId/follow';

  static String communityFollowStats(String userId) =>
      '$_base/community/users/$userId/follow-stats';

  static String communityFollowing(String userId) =>
      '$_base/community/users/$userId/following';

  static String communityFollowers(String userId) =>
      '$_base/community/users/$userId/followers';

  // ── Discussions ───────────────────────────────────────────────────────
  static const communityDiscussions = '$_base/community/discussions';
  static String communityDiscussionDetail(String discussionId) =>
      '$_base/community/discussions/$discussionId';
  static String communityDiscussionComments(String discussionId) =>
      '$_base/community/discussions/$discussionId/comments';
  static String communityDiscussionCommentReplies(String commentId) =>
      '$_base/community/discussions/comments/$commentId/replies';
  static String communityDiscussionReact(String discussionId) =>
      '$_base/community/discussions/$discussionId/react';
  static String communityDiscussionReactions(String discussionId) =>
      '$_base/community/discussions/$discussionId/reactions';
  static String communityDiscussionReport(String discussionId) =>
      '$_base/community/discussions/$discussionId/report';
  static String communityDiscussionCommentLike(String commentId) =>
      '$_base/community/discussions/comments/$commentId/like';
  static String communityDiscussionComment(String commentId) =>
      '$_base/community/discussions/comments/$commentId';
  // Compatibility name used by the merged discussion datasource.
  static String communityDiscussionCommentDetail(String commentId) =>
      communityDiscussionComment(commentId);

  static const communityEvents = '$_base/community/events';

  static String communityEventDetail(String eventId) =>
      '$_base/community/events/$eventId';

  static String communityEventRsvp(String eventId) =>
      '$_base/community/events/$eventId/rsvp';

  static String communityEventAttendees(String eventId) =>
      '$_base/community/events/$eventId/attendees';

  // ── Stories ────────────────────────────────────────────────────────────
  static const stories = '$_base/community/stories';

  static String storyItem(String storyId) =>
      '$_base/community/stories/$storyId';

  static String storyView(String storyId) =>
      '$_base/community/stories/$storyId/view';

  static String storyLike(String storyId) =>
      '$_base/community/stories/$storyId/like';

  static String storyViewers(String storyId) =>
      '$_base/community/stories/$storyId/viewers';

  // ── Notifications ─────────────────────────────────────────────────────
  static const notifications = '$_base/notifications';
  static const notificationUnreadCount = '$_base/notifications/unread-count';
  static const notificationReadAll = '$_base/notifications/read-all';
  static String notificationRead(String notificationId) =>
      '$_base/notifications/$notificationId/read';
  static const notificationDevices =
      '$_base/profile/settings/notifications/devices';

  static String notificationDevice(String deviceId) =>
      '$_base/profile/settings/notifications/devices/$deviceId';

  // ── Chats ─────────────────────────────────────────────────────────────
  static const chats = '$_base/community/chats';
  static const chatUnreadCount = '$_base/community/chats/unread-count';

  // ── Entertainment / Gamification ──────────────────────────────────────
  static const quizzes = '$_base/entertainment/quizzes';
  static String quizDetail(String quizId) =>
      '$_base/entertainment/quizzes/$quizId';
  static String quizAttempt(String quizId) =>
      '$_base/entertainment/quizzes/$quizId/attempts';
  static const quizHistory = '$_base/entertainment/quizzes/history';
  static const leaderboards = '$_base/entertainment/leaderboards';

  // ── Search ────────────────────────────────────────────────────────────
  static const search = '$_base/search';
  static const searchPeople = '$_base/search/people';
  static const searchPosts = '$_base/search/posts';
  static const searchEvents = '$_base/search/events';
  static const searchDiscussions = '$_base/search/discussions';
  static const trendingHashtags = '$_base/community/hashtags/trending';
}
