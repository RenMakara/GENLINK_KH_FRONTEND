import 'package:flutter/material.dart';
import '../../domain/models/story_model.dart';

export '../../domain/models/story_model.dart' show StoryAuthor;

// ---------------------------------------------------------------------------
// PRODUCTION NOTE: All demo/mock Story data has been removed.
//
// This file is kept to prevent compilation errors in story_viewer_screen.dart
// and other files that reference DemoStoryModel.
//
// kDemoStories is intentionally EMPTY. getDemoStoryGroups() returns [].
// getDemoStoryById() always returns null.
//
// The Story tray displays ONLY real authenticated-user Stories and real backend
// Stories. No fake users, no placeholder content, no hardcoded names.
// ---------------------------------------------------------------------------

/// Always empty in production. Do NOT add fake Story users here.
final List<DemoStoryModel> kDemoStories = [];

/// Always returns an empty list. The Story tray uses only real backend data.
List<StoryGroupModel> getDemoStoryGroups() => [];

/// Always returns null — no demo stories exist.
DemoStoryModel? getDemoStoryById(String storyId) => null;

void updateDemoStoryLike(String storyId, bool isLiked, int likesCount) {}

void markDemoStoryViewed(String storyId) {}

// ---------------------------------------------------------------------------
// Stub class kept for backward compatibility with story_viewer_screen.dart
// Do NOT instantiate or use DemoStoryModel for real UI rendering.
// With kDemoStories empty, getDemoStoryById() always returns null and
// these fields are never accessed at runtime.
// ---------------------------------------------------------------------------
class DemoStoryModel {
  final StoryAuthor author;
  final String storyContent;
  final DateTime createdAt;
  final String timeAgo;
  final String? location;
  final List<Color> gradientColors;
  final IconData? icon;
  final String? tag;
  int likesCount;
  bool isLiked;
  bool isViewed;

  DemoStoryModel({
    required this.author,
    required this.storyContent,
    required this.createdAt,
    this.timeAgo = '2h ago',
    this.location,
    this.gradientColors = const [],
    this.icon,
    this.tag,
    this.likesCount = 0,
    this.isLiked = false,
    this.isViewed = false,
  });

  String get userId => author.id;
  String get userName => author.name;
  String get avatarUrl => author.avatarUrl;
  String get id => 'demo_${author.id}';
  String get userAvatar => author.avatarUrl;
  String get content => storyContent;
}
