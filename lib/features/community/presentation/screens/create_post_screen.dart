import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_post_model.dart';
import '../controllers/community_controller.dart';

class GenLinkRichTextController extends TextEditingController {
  final Set<int> boldIndices = {};
  final Set<int> italicIndices = {};
  final Set<int> underlineIndices = {};

  bool isCurrentBold = false;
  bool isCurrentItalic = false;
  bool isCurrentUnderline = false;

  void toggleBold() {
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      final allBold = List.generate(end - start, (i) => start + i).every((idx) => boldIndices.contains(idx));

      for (int i = start; i < end; i++) {
        if (allBold) {
          boldIndices.remove(i);
        } else {
          boldIndices.add(i);
        }
      }
    } else {
      isCurrentBold = !isCurrentBold;
    }
    notifyListeners();
  }

  void toggleItalic() {
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      final allItalic = List.generate(end - start, (i) => start + i).every((idx) => italicIndices.contains(idx));

      for (int i = start; i < end; i++) {
        if (allItalic) {
          italicIndices.remove(i);
        } else {
          italicIndices.add(i);
        }
      }
    } else {
      isCurrentItalic = !isCurrentItalic;
    }
    notifyListeners();
  }

  void toggleUnderline() {
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      final allUnderline = List.generate(end - start, (i) => start + i).every((idx) => underlineIndices.contains(idx));

      for (int i = start; i < end; i++) {
        if (allUnderline) {
          underlineIndices.remove(i);
        } else {
          underlineIndices.add(i);
        }
      }
    } else {
      isCurrentUnderline = !isCurrentUnderline;
    }
    notifyListeners();
  }

  bool get isBoldActive {
    if (selection.isValid && !selection.isCollapsed) {
      return List.generate(selection.end - selection.start, (i) => selection.start + i)
          .every((idx) => boldIndices.contains(idx));
    }
    return isCurrentBold;
  }

  bool get isItalicActive {
    if (selection.isValid && !selection.isCollapsed) {
      return List.generate(selection.end - selection.start, (i) => selection.start + i)
          .every((idx) => italicIndices.contains(idx));
    }
    return isCurrentItalic;
  }

  bool get isUnderlineActive {
    if (selection.isValid && !selection.isCollapsed) {
      return List.generate(selection.end - selection.start, (i) => selection.start + i)
          .every((idx) => underlineIndices.contains(idx));
    }
    return isCurrentUnderline;
  }

  @override
  set value(TextEditingValue newValue) {
    final oldLength = text.length;
    final newLength = newValue.text.length;

    if (newLength > oldLength) {
      final addedCount = newLength - oldLength;
      final insertStart = newValue.selection.start >= addedCount ? newValue.selection.start - addedCount : 0;

      final newBold = <int>{};
      for (final idx in boldIndices) {
        newBold.add(idx >= insertStart ? idx + addedCount : idx);
      }
      final newItalic = <int>{};
      for (final idx in italicIndices) {
        newItalic.add(idx >= insertStart ? idx + addedCount : idx);
      }
      final newUnderline = <int>{};
      for (final idx in underlineIndices) {
        newUnderline.add(idx >= insertStart ? idx + addedCount : idx);
      }

      for (int i = 0; i < addedCount; i++) {
        final charIndex = insertStart + i;
        if (isCurrentBold) newBold.add(charIndex);
        if (isCurrentItalic) newItalic.add(charIndex);
        if (isCurrentUnderline) newUnderline.add(charIndex);
      }

      boldIndices.clear();
      boldIndices.addAll(newBold);
      italicIndices.clear();
      italicIndices.addAll(newItalic);
      underlineIndices.clear();
      underlineIndices.addAll(newUnderline);
    } else if (newLength < oldLength) {
      final removedCount = oldLength - newLength;
      final deleteStart = newValue.selection.start;

      final newBold = <int>{};
      for (final idx in boldIndices) {
        if (idx < deleteStart) {
          newBold.add(idx);
        } else if (idx >= deleteStart + removedCount) {
          newBold.add(idx - removedCount);
        }
      }
      final newItalic = <int>{};
      for (final idx in italicIndices) {
        if (idx < deleteStart) {
          newItalic.add(idx);
        } else if (idx >= deleteStart + removedCount) {
          newItalic.add(idx - removedCount);
        }
      }
      final newUnderline = <int>{};
      for (final idx in underlineIndices) {
        if (idx < deleteStart) {
          newUnderline.add(idx);
        } else if (idx >= deleteStart + removedCount) {
          newUnderline.add(idx - removedCount);
        }
      }

      boldIndices.clear();
      boldIndices.addAll(newBold);
      italicIndices.clear();
      italicIndices.addAll(newItalic);
      underlineIndices.clear();
      underlineIndices.addAll(newUnderline);
    }

    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final children = <InlineSpan>[];
    final baseStyle = style ?? const TextStyle(color: Colors.white, fontSize: 17, height: 1.45);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isBold = boldIndices.contains(i);
      final isItalic = italicIndices.contains(i);
      final isUnderline = underlineIndices.contains(i);

      TextStyle charStyle = baseStyle;
      if (isBold) {
        charStyle = charStyle.copyWith(fontWeight: FontWeight.bold);
      }
      if (isItalic) {
        charStyle = charStyle.copyWith(fontStyle: FontStyle.italic);
      }
      if (isUnderline) {
        charStyle = charStyle.copyWith(decoration: TextDecoration.underline);
      }

      children.add(TextSpan(text: char, style: charStyle));
    }

    return TextSpan(style: baseStyle, children: children);
  }
}

class CreatePostScreen extends StatefulWidget {
  final CommunityPostModel? initialPost;

  const CreatePostScreen({super.key, this.initialPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GenLinkRichTextController _textController = GenLinkRichTextController();
  final FocusNode _editorFocusNode = FocusNode();

  String _selectedAudience = 'Public';
  final Set<String> _selectedTags = {};
  List<String> _attachedImages = [];

  String? _selectedLocation;

  // Poll state
  String? _pollQuestion;
  List<String> _pollOptionsList = [];
  String _pollDuration = '3 Days';
  bool _allowMultipleAnswers = false;

  // Link state
  String? _attachedLink;
  String? _linkTitle;
  String? _linkDomain;

  bool _isSubmitting = false;
  final int _maxCharacters = 500;

  bool get _isEditing => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _textController.text = widget.initialPost!.content;
      _attachedImages = List.from(widget.initialPost!.imageUrls);
      _selectedAudience = widget.initialPost!.visibility;
      _selectedLocation = widget.initialPost!.location;
      _attachedLink = widget.initialPost!.linkUrl;
      _linkTitle = widget.initialPost!.linkPreviewTitle;
      _linkDomain = widget.initialPost!.linkPreviewDomain;
      _pollQuestion = widget.initialPost!.pollQuestion;
      if (widget.initialPost!.pollOptions != null) {
        _pollOptionsList = widget.initialPost!.pollOptions!.map((o) => o.text).toList();
      }
    } else {
      _attachedImages = [];
    }
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> selected = await _picker.pickMultiImage();
      if (selected.isNotEmpty) {
        setState(() {
          _attachedImages.addAll(selected.map((e) => e.path));
        });
      }
    } catch (_) {}
  }

  bool get _canPost {
    final text = _textController.text.trim();
    return text.isNotEmpty || _attachedImages.isNotEmpty || _pollQuestion != null || _attachedLink != null;
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 16),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET 1: TOPICS
  // ---------------------------------------------------------------------------
  void _showTopicsSheet() {
    final customController = TextEditingController();
    final searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final List<String> availableTopics = [
            '#Flutter',
            '#Workshop',
            '#CampusLink',
            '#TechExpo',
            '#CambodiaDev',
            '#Hackathon2026',
            '#StudentLife',
            '#UIUXDesign',
          ].where((t) => t.toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Topics",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${_selectedTags.length} / 5 Selected",
                        style: const TextStyle(color: AppColors.communityAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Topics
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) {
                      setSheetState(() => searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: "Search topics...",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: AppColors.darkSurfaceSecondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Custom Topic Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Create custom topic...",
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.darkSurfaceSecondary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = customController.text.trim();
                          if (text.isNotEmpty && _selectedTags.length < 5) {
                            final tag = text.startsWith('#') ? text : '#$text';
                            setState(() {
                              _selectedTags.add(tag);
                            });
                            setSheetState(() {});
                            customController.clear();
                          } else if (_selectedTags.length >= 5) {
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Maximum Topics Reached",
                              message: "You can select up to 5 topics.",
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.communityAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Add", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Selected Topics Wrap
                  if (_selectedTags.isNotEmpty) ...[
                    const Text("Selected", style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedTags.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(color: AppColors.communityAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.communityAccent),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                            setSheetState(() {});
                          },
                          backgroundColor: AppColors.communityAccent.withValues(alpha: 0.18),
                          side: const BorderSide(color: AppColors.communityAccent, width: 1.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recommended Topics Wrap
                  const Text("Recommended Topics", style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTopics.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val && _selectedTags.length >= 5) {
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Maximum Topics",
                              message: "You can select up to 5 topics.",
                            );
                            return;
                          }
                          setState(() {
                            if (val) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          setSheetState(() {});
                        },
                        selectedColor: AppColors.communityAccent.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.communityAccent,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.communityAccent : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: AppColors.darkSurfaceSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Done", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET 2: LOCATION
  // ---------------------------------------------------------------------------
  void _showLocationSheet() {
    final searchController = TextEditingController();
    String locQuery = '';

    final List<String> places = [
      'RUPP Campus 1 (Royal University of Phnom Penh)',
      'CADT Innovation Center',
      'ITC Campus (Institute of Technology of Cambodia)',
      'ACLEDA Institute of Business',
      'Phnom Penh, Cambodia',
      'Siem Reap Cultural Hub',
      'Battambang Campus',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = places.where((p) => p.toLowerCase().contains(locQuery.toLowerCase())).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const Text(
                    "Add Location",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Search input
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) => setSheetState(() => locQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search university, city or landmark...",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: AppColors.darkSurfaceSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.my_location, color: AppColors.danger, size: 18),
                    ),
                    title: const Text("Use Current Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Phnom Penh, Cambodia", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedLocation = "Phnom Penh, Cambodia";
                      });
                    },
                  ),

                  const Divider(color: AppColors.darkBorderSubtle),

                  ...filtered.map(
                    (place) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.communityAccent, size: 20),
                      title: Text(place, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedLocation = place;
                        });
                      },
                    ),
                  ),

                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedLocation = null;
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                      label: const Text("Remove Attached Location", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET 3: POLL CREATOR
  // ---------------------------------------------------------------------------
  void _showPollCreatorSheet() {
    final qController = TextEditingController(text: _pollQuestion ?? '');
    final List<TextEditingController> optionControllers = [];

    if (_pollOptionsList.isNotEmpty) {
      for (var opt in _pollOptionsList) {
        optionControllers.add(TextEditingController(text: opt));
      }
    } else {
      optionControllers.add(TextEditingController());
      optionControllers.add(TextEditingController());
    }

    String selectedDuration = _pollDuration;
    bool allowMultiple = _allowMultipleAnswers;
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDragHandle(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Create Poll",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_pollQuestion != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _pollQuestion = null;
                                _pollOptionsList = [];
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text("Remove Poll", style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question Input
                    TextField(
                      controller: qController,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Ask a question...",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Options List (Min 2, Max 6)
                    ...List.generate(optionControllers.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[idx],
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: "Option ${idx + 1}",
                                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                  filled: true,
                                  fillColor: AppColors.darkSurfaceSecondary,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            if (optionControllers.length > 2) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                                onPressed: () {
                                  setSheetState(() {
                                    optionControllers.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    if (optionControllers.length < 6)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              optionControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.communityAccent, size: 18),
                          label: const Text("Add Option", style: TextStyle(color: AppColors.communityAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Duration Selector
                    const Text("Poll Duration", style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['1 Day', '3 Days', '7 Days'].map((dur) {
                        final isSel = selectedDuration == dur;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(dur),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedDuration = dur);
                            },
                            selectedColor: AppColors.communityAccent.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.communityAccent : Colors.white70,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: AppColors.darkSurfaceSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Switches
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Allow Multiple Answers", style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: allowMultiple,
                      activeTrackColor: AppColors.communityAccent,
                      onChanged: (val) => setSheetState(() => allowMultiple = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Anonymous Poll", style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: isAnonymous,
                      activeTrackColor: AppColors.communityAccent,
                      onChanged: (val) => setSheetState(() => isAnonymous = val),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          final question = qController.text.trim();
                          final validOpts = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                          if (question.isEmpty || validOpts.length < 2) {
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Incomplete Poll",
                              message: "Please enter a question and at least 2 options.",
                            );
                            return;
                          }

                          setState(() {
                            _pollQuestion = question;
                            _pollOptionsList = validOpts;
                            _pollDuration = selectedDuration;
                            _allowMultipleAnswers = allowMultiple;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Save Poll", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET 4: LINK ATTACHMENT
  // ---------------------------------------------------------------------------
  void _showAttachLinkDialog() {
    final linkController = TextEditingController(text: _attachedLink ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final url = linkController.text.trim();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Attach Web Link", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_attachedLink != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _attachedLink = null;
                              _linkTitle = null;
                              _linkDomain = null;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text("Remove", style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: linkController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText: "https://example.com/article...",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.darkSurfaceSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Live Preview Card
                  if (url.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.communityAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.communityAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.link_rounded, color: AppColors.communityAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  url.contains('github') ? 'GitHub Code Repository' : 'CampusLink Resource Page',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Uri.tryParse(url)?.host ?? 'campuslink.kh',
                                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        if (url.isNotEmpty) {
                          setState(() {
                            _attachedLink = url;
                            _linkDomain = Uri.tryParse(url)?.host ?? 'campuslink.kh';
                            _linkTitle = url.contains('github') ? 'GitHub Code Repository' : 'CampusLink Resource Page';
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.communityAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Attach Link", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _insertTextAtCursor(String insertText) {
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(start, start, insertText);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: start + insertText.length);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _attachedImages.removeAt(oldIndex);
      _attachedImages.insert(newIndex, item);
    });
  }

  void _onBackPress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;

    if (_canPost && !_isSubmitting) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: surfaceSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Discard Post Draft?", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: Text("If you leave now, your draft will be discarded.", style: TextStyle(color: textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Keep Editing", style: TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Discard", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submitPost() {
    if (!_canPost || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final controller = Get.find<CommunityController>();

    List<PollOptionModel>? pollOpts;
    if (_pollQuestion != null && _pollOptionsList.isNotEmpty) {
      pollOpts = _pollOptionsList.map((text) => PollOptionModel(text: text)).toList();
    }

    if (_isEditing) {
      controller.updatePost(
        postId: widget.initialPost!.id,
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        visibility: _selectedAudience,
        location: _selectedLocation,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
      );

      AppNotificationBanner.showSuccess(
        context: context,
        title: "Post Updated",
        message: "Your changes have been saved immediately.",
      );
    } else {
      controller.createPost(
        content: _textController.text.trim(),
        imageUrls: _attachedImages,
        visibility: _selectedAudience,
        location: _selectedLocation,
        linkUrl: _attachedLink,
        linkPreviewTitle: _linkTitle,
        linkPreviewDomain: _linkDomain,
        pollQuestion: _pollQuestion,
        pollOptions: pollOpts,
        pollDuration: _pollDuration,
      );

      AppNotificationBanner.showSuccess(
        context: context,
        title: "Post Created",
        message: "Your post is now live in the community feed.",
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfacePrimary = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final currentLength = _textController.text.length;

    return PopScope(
      canPop: !_canPost || _isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: textPrimary, size: 24),
            onPressed: _onBackPress,
          ),
          title: Text(
            _isEditing ? 'community.editPost'.tr : 'community.createPost'.tr,
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _canPost && !_isSubmitting ? _submitPost : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textPrimary,
                  disabledBackgroundColor: isDark ? Colors.white24 : AppColors.lightBorderSubtle,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white),
                      )
                    : Text(
                        _isEditing ? 'common.save'.tr : 'community.post'.tr,
                        style: TextStyle(
                          color: _canPost ? (isDark ? Colors.black : Colors.white) : textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Header & Visibility Selector
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage('assets/images/user_profile.png'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sokny Enat",
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: surfacePrimary,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: ['Public', 'Friends', 'Only Me'].map((aud) {
                                        return ListTile(
                                          title: Text(
                                            aud == 'Public' ? 'privacy.PUBLIC'.tr : (aud == 'Friends' ? 'privacy.FRIENDS'.tr : 'privacy.PRIVATE'.tr),
                                            style: TextStyle(color: textPrimary),
                                          ),
                                          trailing: _selectedAudience == aud ? const Icon(Icons.check, color: AppColors.communityAccent) : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedAudience = aud;
                                            });
                                            Navigator.pop(ctx);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: surfaceSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedAudience == 'Public' ? '🌍 ${'privacy.PUBLIC'.tr}' : (_selectedAudience == 'Friends' ? '👥 ${'privacy.FRIENDS'.tr}' : '🔒 ${'privacy.PRIVATE'.tr}'),
                                      style: TextStyle(color: textSecondary, fontSize: 11),
                                    ),
                                    Icon(Icons.arrow_drop_down, color: textSecondary, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Clean Auto-Expanding Visual Rich Text Editor Input
                    TextField(
                      controller: _textController,
                      focusNode: _editorFocusNode,
                      minLines: 3,
                      maxLines: null,
                      style: TextStyle(color: textPrimary, fontSize: 18, height: 1.45),
                      decoration: InputDecoration(
                        hintText: 'community.whatsHappening'.tr,
                        hintStyle: TextStyle(color: textMuted, fontSize: 18, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Attached Media Section with Image Reordering
                    if (_attachedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length + 1,
                          itemBuilder: (ctx, idx) {
                            if (idx == _attachedImages.length) {
                              return InkWell(
                                onTap: _pickGalleryImages,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: surfaceSecondary,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderSubtle),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.communityAccent, size: 30),
                                      const SizedBox(height: 6),
                                      Text("Add More", style: TextStyle(color: textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final imgPath = _attachedImages[idx];
                            return Stack(
                              children: [
                                Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: imgPath.startsWith('http')
                                          ? NetworkImage(imgPath) as ImageProvider
                                          : FileImage(File(imgPath)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Remove Image Button
                                Positioned(
                                  top: 6,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _attachedImages.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xB3000000),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                                // Move Left / Right Buttons
                                if (_attachedImages.length > 1)
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Row(
                                      children: [
                                        if (idx > 0)
                                          GestureDetector(
                                            onTap: () => _reorderImages(idx, idx - 1),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        const SizedBox(width: 4),
                                        if (idx < _attachedImages.length - 1)
                                          GestureDetector(
                                            onTap: () => _reorderImages(idx, idx + 2),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Attached Badges
                    if (_selectedTags.isNotEmpty || _selectedLocation != null || _pollQuestion != null || _attachedLink != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._selectedTags.map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(color: AppColors.communityAccent, fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.communityAccent),
                                onDeleted: () {
                                  setState(() {
                                    _selectedTags.remove(tag);
                                  });
                                },
                                backgroundColor: AppColors.communityAccent.withValues(alpha: 0.15),
                              )),
                          if (_selectedLocation != null)
                            Chip(
                              avatar: const Icon(Icons.location_on, color: AppColors.danger, size: 14),
                              label: Text(_selectedLocation!, style: TextStyle(color: textPrimary, fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 14, color: textSecondary),
                              onDeleted: () => setState(() => _selectedLocation = null),
                              backgroundColor: surfaceSecondary,
                            ),
                          if (_pollQuestion != null)
                            Chip(
                              avatar: const Icon(Icons.poll, color: AppColors.warning, size: 14),
                              label: Text("Poll: $_pollQuestion", style: TextStyle(color: textPrimary, fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 14, color: textSecondary),
                              onDeleted: () => setState(() {
                                _pollQuestion = null;
                                _pollOptionsList = [];
                              }),
                              backgroundColor: surfaceSecondary,
                            ),
                          if (_attachedLink != null)
                            Chip(
                              avatar: const Icon(Icons.link, color: AppColors.communityAccent, size: 14),
                              label: Text(_linkDomain ?? "Link", style: TextStyle(color: textPrimary, fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 14, color: textSecondary),
                              onDeleted: () => setState(() {
                                _attachedLink = null;
                                _linkTitle = null;
                                _linkDomain = null;
                              }),
                              backgroundColor: surfaceSecondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Smart Character Counter
            if (currentLength > 450)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "$currentLength / $_maxCharacters",
                      style: TextStyle(
                        color: currentLength >= _maxCharacters ? AppColors.danger : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            Divider(color: borderSubtle, height: 1),

            // Formatting Toolbar & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Contextual Formatting Toolbar (Bold, Italic, Underline, Emoji, Mentions, Hashtags)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Bold Toggle
                          InkWell(
                            onTap: () {
                              _textController.toggleBold();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _textController.isBoldActive ? textPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "B",
                                style: TextStyle(
                                  color: _textController.isBoldActive ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Italic Toggle
                          InkWell(
                            onTap: () {
                              _textController.toggleItalic();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _textController.isItalicActive ? textPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "I",
                                style: TextStyle(
                                  color: _textController.isItalicActive ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Underline Toggle
                          InkWell(
                            onTap: () {
                              _textController.toggleUnderline();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _textController.isUnderlineActive ? textPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "U",
                                style: TextStyle(
                                  color: _textController.isUnderlineActive ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _textController.isUnderlineActive ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.numbers_rounded, color: AppColors.communityAccent, size: 20),
                            tooltip: "Add Hashtag",
                            onPressed: _showTopicsSheet,
                          ),
                          IconButton(
                            icon: Icon(Icons.alternate_email_rounded, color: textPrimary, size: 20),
                            tooltip: "Mention User",
                            onPressed: () => _insertTextAtCursor('@SoknyEnat '),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.yellowAccent, size: 20),
                            tooltip: "Emoji",
                            onPressed: () => _insertTextAtCursor('🔥 '),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.photo_library_outlined, color: AppColors.communityAccent, size: 20),
                            onPressed: _pickGalleryImages,
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_on_outlined, color: AppColors.communityAccent, size: 20),
                            onPressed: _showLocationSheet,
                          ),
                          IconButton(
                            icon: const Icon(Icons.poll_outlined, color: AppColors.communityAccent, size: 20),
                            onPressed: _showPollCreatorSheet,
                          ),
                          IconButton(
                            icon: const Icon(Icons.link_rounded, color: AppColors.communityAccent, size: 20),
                            onPressed: _showAttachLinkDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
