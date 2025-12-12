import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/extensions.dart';
import '../../domain/models/stage_result.dart';
import '../theme/executive_theme.dart';

/// Tabbed view for displaying council stages.
class StageTabsWidget extends StatefulWidget {
  final List<ModelResponseResult>? stage1;
  final List<RankingResult>? stage2;
  final SynthesisResult? stage3;
  final CouncilMetadata? metadata;
  final bool isLoading;
  final bool stage1Loading;
  final bool stage2Loading;
  final bool stage3Loading;

  const StageTabsWidget({
    super.key,
    this.stage1,
    this.stage2,
    this.stage3,
    this.metadata,
    this.isLoading = false,
    this.stage1Loading = false,
    this.stage2Loading = false,
    this.stage3Loading = false,
  });

  @override
  State<StageTabsWidget> createState() => _StageTabsWidgetState();
}

class _StageTabsWidgetState extends State<StageTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedStage1Index = 0;
  int _selectedStage2Index = 0;

  @override
  void initState() {
    super.initState();
    // Start on the most relevant tab based on available data
    int initialIndex = 0;
    if (widget.stage3 != null) {
      initialIndex = 2;
    } else if (widget.stage2 != null && widget.stage2!.isNotEmpty) {
      initialIndex = 1;
    } else if (widget.stage1 != null && widget.stage1!.isNotEmpty) {
      initialIndex = 0;
    }
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ExecutiveTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: ExecutiveTheme.surfaceColor.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab('Opinions', widget.stage1?.length ?? 0,
                    widget.stage1Loading),
                _buildTab('Rankings', widget.stage2?.length ?? 0,
                    widget.stage2Loading),
                _buildTab('Final', widget.stage3 != null ? 1 : 0,
                    widget.stage3Loading),
              ],
            ),
          ),
          // Tab content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return AnimatedSwitcher(
                duration: 200.ms,
                child: _buildTabContent(_tabController.index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count, bool isLoading) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ExecutiveTheme.goldAccent,
              ),
            )
          else if (count > 0)
            const Icon(
              Icons.check_circle,
              size: 14,
              color: ExecutiveTheme.successColor,
            ),
        ],
      ),
    );
  }

  void _showRankingExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How Rankings Work'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Higher score = Better response'),
            SizedBox(height: 8),
            Text('• Each model anonymously ranks all responses'),
            SizedBox(height: 8),
            Text('• 1st place gets most points, last place gets fewest'),
            SizedBox(height: 8),
            Text('• Scores are summed across all evaluators'),
            SizedBox(height: 8),
            Text('• Models can\'t recognize their own response'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildStage1Content();
      case 1:
        return _buildStage2Content();
      case 2:
        return _buildStage3Content();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStage1Content() {
    if (widget.stage1 == null || widget.stage1!.isEmpty) {
      return _buildEmptyState('Waiting for model responses...');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.stage1!.length, (index) {
                final result = widget.stage1![index];
                final isSelected = index == _selectedStage1Index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(result.model.modelDisplayName.truncate(15)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedStage1Index = index),
                    selectedColor: ExecutiveTheme.goldAccent.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ExecutiveTheme.goldAccent
                          : ExecutiveTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Response content
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: widget.stage1![_selectedStage1Index].response,
                styleSheet: _markdownStyleSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage2Content() {
    if (widget.stage2 == null || widget.stage2!.isEmpty) {
      return _buildEmptyState('Waiting for peer rankings...');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aggregate rankings
          if (widget.metadata?.aggregateRankings != null) ...[
            Row(
              children: [
                Text(
                  'Aggregate Rankings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ExecutiveTheme.goldAccent,
                      ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showRankingExplanation(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: ExecutiveTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.metadata!.aggregateRankings.map((ranking) {
              return _buildRankingBar(ranking);
            }),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          // Model selector
          Text(
            'Individual Evaluations',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ExecutiveTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.stage2!.length, (index) {
                final result = widget.stage2![index];
                final isSelected = index == _selectedStage2Index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(result.model.modelDisplayName.truncate(15)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedStage2Index = index),
                    selectedColor: ExecutiveTheme.goldAccent.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ExecutiveTheme.goldAccent
                          : ExecutiveTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: _deAnonymizeRanking(
                    widget.stage2![_selectedStage2Index].ranking),
                styleSheet: _markdownStyleSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingBar(AggregateRanking ranking) {
    final maxModels = widget.stage1?.length ?? 4;
    final normalizedScore = 1 - ((ranking.averageRank - 1) / (maxModels - 1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              ranking.model.modelDisplayName.truncate(12),
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: normalizedScore.clamp(0.0, 1.0),
                backgroundColor: ExecutiveTheme.surfaceColor,
                valueColor: AlwaysStoppedAnimation(
                  Color.lerp(
                    ExecutiveTheme.errorColor,
                    ExecutiveTheme.successColor,
                    normalizedScore,
                  )!,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${ranking.averageRank.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ExecutiveTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage3Content() {
    if (widget.stage3 == null) {
      return _buildEmptyState('Waiting for final synthesis...');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: ExecutiveTheme.goldAccent.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ExecutiveTheme.goldAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gavel,
                      size: 14,
                      color: ExecutiveTheme.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Chairman: ${widget.stage3!.model.modelDisplayName}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ExecutiveTheme.goldAccent,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: widget.stage3!.response,
            styleSheet: _markdownStyleSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ExecutiveTheme.goldAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _deAnonymizeRanking(String text) {
    if (widget.metadata?.labelToModel == null) return text;

    String result = text;
    for (final entry in widget.metadata!.labelToModel.entries) {
      result = result.replaceAll(
        entry.key,
        '**${entry.value.modelDisplayName}**',
      );
    }
    return result;
  }

  MarkdownStyleSheet get _markdownStyleSheet {
    return MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodyMedium,
      h1: Theme.of(context).textTheme.headlineMedium,
      h2: Theme.of(context).textTheme.headlineSmall,
      h3: Theme.of(context).textTheme.titleLarge,
      code: TextStyle(
        backgroundColor: ExecutiveTheme.surfaceColor,
        color: ExecutiveTheme.goldAccent,
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: ExecutiveTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: ExecutiveTheme.goldAccent.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
    );
  }
}
