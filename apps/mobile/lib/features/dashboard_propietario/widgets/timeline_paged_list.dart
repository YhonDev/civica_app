import 'package:flutter/material.dart';

import '../../../shared/widgets/timeline_widget.dart';
import '../../../core/theme/app_spacing.dart';

/// A scrollable list of TimelineItems with infinite scroll pagination.
///
/// Shows a [CircularProgressIndicator] at the bottom while loading more items.
/// Calls [onLoadMore] when the user scrolls near the bottom.
class TimelinePagedList extends StatefulWidget {
  final List<TimelineItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(TimelineItem item)? onItemTap;

  const TimelinePagedList({
    super.key,
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
  });

  @override
  State<TimelinePagedList> createState() => _TimelinePagedListState();
}

class _TimelinePagedListState extends State<TimelinePagedList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        widget.hasMore &&
        !widget.isLoadingMore &&
        widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          // Loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: TimelineWidget(
            items: [widget.items[index]],
            onItemTap: widget.onItemTap,
          ),
        );
      },
    );
  }
}
