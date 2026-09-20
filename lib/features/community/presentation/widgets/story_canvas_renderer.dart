import 'dart:io';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/story_model.dart';
import 'story_template_canvas.dart';
import 'story_video_player_widget.dart';

TextStyle getStoryTextStyle({
  required TextStyleType fontStyle,
  required Color color,
  required TextBgStyle bgStyle,
  TextEffectType effect = TextEffectType.none,
  double fontSize = 28.0,
}) {
  FontWeight weight = FontWeight.w600;
  FontStyle style = FontStyle.normal;
  double letterSpacing = 0.2;
  double height = 1.25;
  List<Shadow>? textShadows;
  String? fontFamily;

  switch (fontStyle) {
    case TextStyleType.classic:
      weight = FontWeight.w600;
      letterSpacing = 0.2;
      break;
    case TextStyleType.elegant:
      style = FontStyle.italic;
      weight = FontWeight.w600;
      letterSpacing = 0.8;
      break;
    case TextStyleType.bold:
      weight = FontWeight.w900;
      letterSpacing = -0.3;
      break;
    case TextStyleType.modern:
      weight = FontWeight.w800;
      letterSpacing = 0.8;
      break;
    case TextStyleType.minimal:
      weight = FontWeight.w700;
      letterSpacing = 1.2;
      break;
    case TextStyleType.handwriting:
      weight = FontWeight.w500;
      style = FontStyle.italic;
      letterSpacing = 0.5;
      break;
    case TextStyleType.coding:
      weight = FontWeight.w600;
      fontFamily = 'monospace';
      letterSpacing = -0.2;
      break;
    case TextStyleType.campus:
      weight = FontWeight.w800;
      letterSpacing = 0.3;
      break;
    case TextStyleType.khmer:
      weight = FontWeight.w600;
      letterSpacing = 0.2;
      break;
    default:
      weight = FontWeight.w700;
      break;
  }

  switch (effect) {
    case TextEffectType.shadow:
      textShadows = [
        Shadow(
          blurRadius: 8.0,
          color: Colors.black.withValues(alpha: 0.85),
          offset: const Offset(0, 2),
        ),
        Shadow(
          blurRadius: 16.0,
          color: Colors.black.withValues(alpha: 0.50),
          offset: const Offset(0, 4),
        ),
      ];
      break;
    case TextEffectType.glow:
      textShadows = [
        Shadow(
          blurRadius: 8.0,
          color: color.withValues(alpha: 0.95),
          offset: Offset.zero,
        ),
        Shadow(
          blurRadius: 20.0,
          color: color.withValues(alpha: 0.85),
          offset: Offset.zero,
        ),
        Shadow(blurRadius: 36.0, color: color, offset: Offset.zero),
      ];
      break;
    case TextEffectType.outline:
    case TextEffectType.none:
      textShadows = null;
      break;
  }

  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: weight,
    fontStyle: style,
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
    height: height,
    shadows: textShadows,
  );
}

File _resolveStoryMediaFile(String rawPath) {
  final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
  return File(clean);
}

bool isStoryVideoPath(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.mp4') ||
      p.endsWith('.mov') ||
      p.endsWith('.m4v') ||
      p.endsWith('.webm') ||
      p.endsWith('.avi') ||
      p.endsWith('.mkv') ||
      p.endsWith('.flv');
}

Widget buildStoryLayerContent({
  required MovableStoryLayer layer,
  required double maxCanvasWidth,
  bool isSelected = false,
  Widget? imageErrorWidget,
}) {
  switch (layer.type) {
    case LayerType.text:
      final hasBg = layer.bgStyle != TextBgStyle.none;
      final baseStyle = getStoryTextStyle(
        fontStyle: layer.fontStyle,
        color: layer.color,
        bgStyle: layer.bgStyle,
        effect: layer.effect,
        fontSize: layer.fontSize,
      );

      final textLuminance = layer.color.computeLuminance();
      final filledBgColor =
          layer.bgColor ??
          (textLuminance > 0.45
              ? Colors.black.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.92));

      final textDisplayColor =
          (layer.bgStyle == TextBgStyle.filled &&
              layer.bgColor == null &&
              layer.color == Colors.white)
          ? Colors.black
          : layer.color;

      Widget textWidget;

      if (layer.effect == TextEffectType.outline) {
        final strokeColor = textLuminance > 0.5 ? Colors.black : Colors.white;
        textWidget = Stack(
          alignment: Alignment.center,
          children: [
            Text(
              layer.text,
              softWrap: true,
              textAlign: layer.alignment,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.5
                  ..color = strokeColor,
                shadows: null,
              ),
            ),
            Text(
              layer.text,
              softWrap: true,
              textAlign: layer.alignment,
              style: baseStyle.copyWith(
                color: textDisplayColor,
                shadows: null,
              ),
            ),
          ],
        );
      } else {
        textWidget = Text(
          layer.text,
          softWrap: true,
          textAlign: layer.alignment,
          style: baseStyle.copyWith(color: textDisplayColor),
        );
      }

      Color? boxColor;
      BoxBorder? boxBorder;
      List<BoxShadow>? boxShadow;

      if (layer.bgStyle == TextBgStyle.filled) {
        boxColor = filledBgColor;
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      } else if (layer.bgStyle == TextBgStyle.rounded) {
        boxColor =
            layer.bgColor?.withValues(alpha: 0.65) ??
            (textLuminance > 0.45
                ? Colors.black.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.80));
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      } else if (layer.bgStyle == TextBgStyle.outline) {
        boxColor = Colors.transparent;
        boxBorder = Border.all(
          color:
              layer.bgColor ??
              layer.color.withValues(alpha: 0.85),
          width: 2.0,
        );
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth * 0.92),
        child: IntrinsicWidth(
          child: Container(
            padding: hasBg
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(14),
              border: isSelected && !hasBg
                  ? Border.all(color: Colors.white38, width: 1.0)
                  : boxBorder,
              boxShadow: boxShadow,
            ),
            child: textWidget,
          ),
        ),
      );

    case LayerType.sticker:
      final isAssetSticker = layer.text.startsWith('assets/');
      if (isAssetSticker) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              layer.text,
              width: 120,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) =>
                  Text(layer.text, style: const TextStyle(fontSize: 48)),
            ),
          ),
        );
      } else {
        return Text(layer.text, style: const TextStyle(fontSize: 54));
      }

    case LayerType.hashtag:
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.communityAccent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.communityAccent.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            layer.text,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              letterSpacing: -0.1,
              height: 1.25,
            ),
          ),
        ),
      );

    case LayerType.mention:
      final cleanMention =
          layer.text.startsWith('@') ? layer.text : '@${layer.text}';
      final hasBg = layer.bgStyle != TextBgStyle.none;
      final textColor = layer.bgStyle == TextBgStyle.filled
          ? Colors.black
          : Colors.white;

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: layer.bgStyle == TextBgStyle.filled
                ? Colors.white
                : (layer.bgStyle == TextBgStyle.rounded
                      ? Colors.black.withValues(alpha: 0.65)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: layer.bgStyle == TextBgStyle.outline
                ? Border.all(color: Colors.white, width: 2.0)
                : null,
            boxShadow: hasBg
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
            child: Text(cleanMention),
          ),
        ),
      );

    case LayerType.location:
      final cleanLocation = layer.text.replaceAll('📍', '').trim();
      final hasBg = layer.bgStyle != TextBgStyle.none;
      final textColor = layer.bgStyle == TextBgStyle.filled
          ? Colors.black
          : Colors.white;

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: layer.bgStyle == TextBgStyle.filled
                ? AppColors.communityAccent
                : (layer.bgStyle == TextBgStyle.rounded
                      ? Colors.black.withValues(alpha: 0.65)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
            border: layer.bgStyle == TextBgStyle.outline
                ? Border.all(color: AppColors.communityAccent, width: 2.0)
                : null,
            boxShadow: hasBg
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: textColor, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  child: Text(
                    cleanLocation,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    case LayerType.music:
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.communityAccent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: AppColors.communityAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  layer.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

    case LayerType.image:
      final localFile = _resolveStoryMediaFile(layer.text);
      Widget imgWidget;
      if (localFile.existsSync()) {
        imgWidget = Image.file(localFile, width: 180, fit: BoxFit.contain);
      } else if (layer.text.startsWith('assets/')) {
        imgWidget = Image.asset(layer.text, width: 180, fit: BoxFit.contain);
      } else {
        imgWidget = Image.network(
          layer.text,
          width: 180,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
              imageErrorWidget ??
              const Icon(Icons.broken_image, color: Colors.white54),
        );
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCanvasWidth),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                )
              : null,
          child: imgWidget,
        ),
      );
  }
}

Widget buildStoryBackground({
  required StoryType storyType,
  String? mediaUrl,
  String? bgGradientStart,
  String? bgGradientEnd,
  double bgScale = 1.0,
  Offset bgOffset = Offset.zero,
  double bgRotation = 0.0,
  Widget? placeholderWidget,
}) {
  Color gStartColor = const Color(0xFF0F172A);
  Color gEndColor = const Color(0xFF1E293B);

  if (bgGradientStart != null && bgGradientEnd != null) {
    try {
      gStartColor = Color(int.parse(bgGradientStart));
      gEndColor = Color(int.parse(bgGradientEnd));
    } catch (_) {}
  }

  if (mediaUrl == null || mediaUrl.isEmpty || storyType == StoryType.text) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gStartColor, gEndColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget mediaWidget;
  if (mediaUrl.startsWith('assets/')) {
    mediaWidget = Image.asset(
      mediaUrl,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) =>
          placeholderWidget ?? const SizedBox.shrink(),
    );
  } else if (isStoryVideoPath(mediaUrl) || storyType == StoryType.video) {
    mediaWidget = StoryVideoPlayerWidget(
      videoUrl: mediaUrl,
      fit: BoxFit.contain,
    );
  } else if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
    mediaWidget = Image.network(
      mediaUrl,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          placeholderWidget ?? const SizedBox.shrink(),
    );
  } else {
    final localFile = _resolveStoryMediaFile(mediaUrl);
    if (localFile.existsSync() ||
        mediaUrl.startsWith('/') ||
        mediaUrl.contains(':\\')) {
      mediaWidget = Image.file(
        localFile,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) =>
            placeholderWidget ?? const SizedBox.shrink(),
      );
    } else {
      mediaWidget = Image.network(
        mediaUrl,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) =>
            placeholderWidget ?? const SizedBox.shrink(),
      );
    }
  }

  return Transform.translate(
    offset: bgOffset,
    child: Transform.scale(
      scale: bgScale,
      child: RotatedBox(
        quarterTurns: (bgRotation / 90).round() % 4,
        child: SizedBox.expand(child: mediaWidget),
      ),
    ),
  );
}

class StoryCanvasRenderer extends StatelessWidget {
  final Size canvasSize;
  final List<MovableStoryLayer> layers;
  final StoryType storyType;
  final String? mediaUrl;
  final String? bgGradientStart;
  final String? bgGradientEnd;
  final double bgScale;
  final Offset bgOffset;
  final double bgRotation;
  final String? textContent;
  final Widget? customBackground;
  final bool isInteractive;
  final String? selectedLayerId;
  final String? editingLayerId;

  final String? templateId;
  final List<StoryTemplateSlot>? templateSlots;

  final ValueChanged<MovableStoryLayer>? onSelectLayer;
  final ValueChanged<MovableStoryLayer>? onEditLayer;
  final void Function(MovableStoryLayer, ScaleStartDetails)? onScaleStartLayer;
  final void Function(MovableStoryLayer, ScaleUpdateDetails)? onScaleUpdateLayer;
  final void Function(MovableStoryLayer, ScaleEndDetails)? onScaleEndLayer;

  const StoryCanvasRenderer({
    super.key,
    required this.canvasSize,
    required this.layers,
    this.storyType = StoryType.photo,
    this.mediaUrl,
    this.bgGradientStart,
    this.bgGradientEnd,
    this.bgScale = 1.0,
    this.bgOffset = Offset.zero,
    this.bgRotation = 0.0,
    this.textContent,
    this.customBackground,
    this.isInteractive = false,
    this.selectedLayerId,
    this.editingLayerId,
    this.templateId,
    this.templateSlots,
    this.onSelectLayer,
    this.onEditLayer,
    this.onScaleStartLayer,
    this.onScaleUpdateLayer,
    this.onScaleEndLayer,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCanvasSize = (canvasSize.width > 0 && canvasSize.height > 0)
        ? canvasSize
        : MediaQuery.of(context).size;
    final maxCanvasWidth = effectiveCanvasSize.width * 0.85;

    final isTemplateStory =
        templateId != null || storyType == StoryType.template;

    StoryTemplateConfig? matchedTemplate;
    if (isTemplateStory) {
      final tid = templateId ?? 'single_polaroid';
      for (final t in storyTemplatePresets) {
        if (t.id == tid) {
          matchedTemplate = t;
          break;
        }
      }
      matchedTemplate ??= storyTemplatePresets.first;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: customBackground ??
              buildStoryBackground(
                storyType: isTemplateStory ? StoryType.text : storyType,
                mediaUrl: isTemplateStory ? null : mediaUrl,
                bgGradientStart: bgGradientStart,
                bgGradientEnd: bgGradientEnd,
                bgScale: bgScale,
                bgOffset: bgOffset,
                bgRotation: bgRotation,
              ),
        ),

        if (isTemplateStory && matchedTemplate != null)
          Positioned.fill(
            child: StoryTemplateCanvas(
              template: matchedTemplate,
              slots: templateSlots ?? const [],
              isInteractive: false,
              customText: textContent,
            ),
          ),

        ...layers.map((layer) {
          if (editingLayerId != null && layer.id == editingLayerId) {
            return const SizedBox.shrink();
          }

          final currentPos = layer.getCanvasOffset(effectiveCanvasSize);
          final isSelected = selectedLayerId == layer.id;

          Widget content = buildStoryLayerContent(
            layer: layer,
            maxCanvasWidth: maxCanvasWidth,
            isSelected: isSelected,
          );

          if (isInteractive) {
            content = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (layer.type == LayerType.text) {
                  onEditLayer?.call(layer);
                } else {
                  onSelectLayer?.call(layer);
                }
              },
              onDoubleTap: () {
                if (layer.type == LayerType.text) {
                  onEditLayer?.call(layer);
                } else if (layer.type == LayerType.image) {
                  layer.scale = 1.0;
                  layer.rotation = 0.0;
                  onSelectLayer?.call(layer);
                }
              },
              onScaleStart: (details) {
                onScaleStartLayer?.call(layer, details);
              },
              onScaleUpdate: (details) {
                onScaleUpdateLayer?.call(layer, details);
              },
              onScaleEnd: (details) {
                onScaleEndLayer?.call(layer, details);
              },
              child: content,
            );
          }

          return Positioned(
            key: ValueKey(layer.id),
            left: currentPos.dx,
            top: currentPos.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Transform.scale(
                scale: layer.scale,
                child: Transform.rotate(
                  angle: layer.rotation,
                  child: content,
                ),
              ),
            ),
          );
        }),

        if (!isTemplateStory &&
            layers.isEmpty &&
            textContent != null &&
            textContent!.trim().isNotEmpty)
          Positioned(
            left: 28,
            right: 28,
            bottom: 120,
            child: Text(
              textContent!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.35,
                shadows: [Shadow(color: Colors.black87, blurRadius: 16)],
              ),
            ),
          ),
      ],
    );
  }
}
