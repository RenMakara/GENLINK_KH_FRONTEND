import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/finance_entities.dart';
import '../controllers/finance_controller.dart';

class FinanceTrendBadge extends StatefulWidget {
  const FinanceTrendBadge({
    super.key,
    required this.metric,
    required this.currency,
    required this.month,
    required this.year,
  });

  final FinanceTrendMetric metric;
  final FinanceCurrency currency;
  final int month;
  final int year;

  @override
  State<FinanceTrendBadge> createState() => _FinanceTrendBadgeState();
}

class _FinanceTrendBadgeState extends State<FinanceTrendBadge> {
  FinanceController get _controller => Get.find<FinanceController>();

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant FinanceTrendBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency ||
        oldWidget.month != widget.month ||
        oldWidget.year != widget.year) {
      _ensureLoaded();
    }
  }

  void _ensureLoaded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _controller.ensureFinanceInsights(
          currency: widget.currency,
          month: widget.month,
          year: widget.year,
        ),
      );
    });
  }

  void _retryLoad() => unawaited(
    _controller.loadFinanceInsights(
      currency: widget.currency,
      month: widget.month,
      year: widget.year,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = _controller.financeInsights.value;
      final matchesScope =
          current?.currency == widget.currency &&
          current?.month == widget.month &&
          current?.year == widget.year;
      final trend = matchesScope ? _controller.trendFor(widget.metric) : null;
      if ((!matchesScope || trend == null) &&
          _controller.isInsightsLoading.value) {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        );
      }
      final requestError =
          _controller.insightsErrorMessage.value ??
          _controller.previousPeriodErrorMessage.value;
      if (requestError != null) {
        return InkWell(
          onTap: _retryLoad,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  matchesScope && trend != null
                      ? '${trend.text} · ${'finance.trend.unavailable'.tr}'
                      : 'finance.trend.unavailable'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }
      final direction = trend?.direction ?? 0;
      final color = direction > 0
          ? AppColors.financeAccent
          : direction < 0
          ? AppColors.danger
          : Theme.of(context).colorScheme.onSurfaceVariant;
      return Text(
        matchesScope
            ? trend?.text ?? 'finance.trend.noBaseline'.tr
            : 'finance.trend.noBaseline'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      );
    });
  }
}

class FinanceInsightsSummaryCard extends StatefulWidget {
  const FinanceInsightsSummaryCard({
    super.key,
    required this.currency,
    required this.month,
    required this.year,
    this.onOpen,
  });

  final FinanceCurrency currency;
  final int month;
  final int year;
  final VoidCallback? onOpen;

  @override
  State<FinanceInsightsSummaryCard> createState() =>
      _FinanceInsightsSummaryCardState();
}

class _FinanceInsightsSummaryCardState
    extends State<FinanceInsightsSummaryCard> {
  FinanceController get _controller => Get.find<FinanceController>();

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant FinanceInsightsSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency ||
        oldWidget.month != widget.month ||
        oldWidget.year != widget.year) {
      _ensureLoaded();
    }
  }

  void _ensureLoaded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _controller.ensureFinanceInsights(
          currency: widget.currency,
          month: widget.month,
          year: widget.year,
        ),
      );
    });
  }

  void _retryLoad() => unawaited(
    _controller.loadFinanceInsights(
      currency: widget.currency,
      month: widget.month,
      year: widget.year,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final data = _controller.financeInsights.value;
      final error = _controller.insightsErrorMessage.value;
      final loading = _controller.isInsightsLoading.value;
      final scopeMatches =
          data?.currency == widget.currency &&
          data?.month == widget.month &&
          data?.year == widget.year;
      final scopedData = scopeMatches ? data : null;
      final insight = scopedData != null && scopedData.insights.isNotEmpty
          ? scopedData.insights.first
          : null;
      final hasAnyData =
          scopedData != null &&
          (scopedData.income != 0 ||
              scopedData.expense != 0 ||
              scopedData.insights.isNotEmpty);

      return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onOpen ?? (error != null ? _retryLoad : null),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.growthAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'finance.smartInsight'.tr,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (error != null && scopeMatches)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _retryLoad,
                              child: Text('common.retry'.tr),
                            ),
                          ],
                        )
                      else if (loading && !scopeMatches)
                        const LinearProgressIndicator(minHeight: 2)
                      else if (error != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _retryLoad,
                              child: Text('common.retry'.tr),
                            ),
                          ],
                        )
                      else
                        Text(
                          insight?.message ??
                              (hasAnyData
                                  ? 'finance.insights.noInsight'.tr
                                  : 'finance.insights.noData'.tr),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.onOpen != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
