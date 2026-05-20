import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/custom_option_model.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/features/surveys/widgets/custom_option_sheet.dart';
import 'package:jup/features/surveys/widgets/survey_card_image.dart';
import 'package:jup/features/surveys/widgets/survey_dialogs.dart';
import 'package:jup/features/surveys/widgets/survey_multiple_choice_content.dart';
import 'package:jup/features/surveys/widgets/survey_yes_no_content.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/comment_section.dart';
import 'package:jup/shared/widgets/text.dart';

class SurveyCard extends ConsumerStatefulWidget {
  final SurveyEntry surveyEntry;
  final int? userId;
  final bool showMedia;
  final VoidCallback? onLoginRequired;
  final bool isNew;
  final bool isJUPAdmin;

  const SurveyCard({
    super.key,
    required this.surveyEntry,
    this.userId,
    this.showMedia = true,
    this.onLoginRequired,
    this.isNew = false,
    this.isJUPAdmin = false,
  });

  @override
  ConsumerState<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends ConsumerState<SurveyCard> {
  bool get _isAdminBlocked =>
      widget.isJUPAdmin && widget.surveyEntry.type == SurveyType.election;

  // Optimistic UI state
  bool? _optimisticYesNoVote;
  String? _optimisticMultipleChoiceVote;
  final Set<String> _optimisticElectionVotes = {};
  final Set<String> _optimisticallyHandledPendingDocIds = {};

  Future<void> _handleYesNoVote(bool voteYes) async {
    if (widget.userId == null) return;

    setState(() => _optimisticYesNoVote = voteYes);

    try {
      final controller = ref.read(surveysControllerProvider);
      final updatedSurvey = await controller.voteOnPoll(
        widget.surveyEntry.documentId,
        widget.userId!,
        voteYes,
      );

      ref
          .read(surveysListProvider.notifier)
          .markVotedInSession(widget.surveyEntry.documentId);
      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);

      if (mounted) setState(() => _optimisticYesNoVote = null);
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticYesNoVote = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _handleMultipleChoiceVote(String optionText) async {
    if (widget.userId == null) return;

    setState(() => _optimisticMultipleChoiceVote = optionText);

    try {
      final controller = ref.read(surveysControllerProvider);
      final updatedSurvey = await controller.voteOnSurvey(
        widget.surveyEntry.documentId,
        widget.userId!,
        optionText,
        widget.surveyEntry.options!,
      );

      ref
          .read(surveysListProvider.notifier)
          .markVotedInSession(widget.surveyEntry.documentId);
      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);

      if (mounted) setState(() => _optimisticMultipleChoiceVote = null);
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticMultipleChoiceVote = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _handleElectionVote(String optionText) async {
    if (widget.userId == null) return;

    setState(() => _optimisticElectionVotes.add(optionText));

    try {
      final controller = ref.read(surveysControllerProvider);
      final updatedSurvey = await controller.voteOnElectionSurvey(
        widget.surveyEntry.documentId,
        widget.userId!,
        optionText,
        widget.surveyEntry.options!,
      );

      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);

      if (mounted) {
        final serverVoteCount =
            updatedSurvey.options?.where((o) => o.currentUserVoted).length ?? 0;

        if (serverVoteCount >= widget.surveyEntry.maxVotes) {
          ref
              .read(surveysListProvider.notifier)
              .markVotedInSession(widget.surveyEntry.documentId);
        }

        setState(() => _optimisticElectionVotes.clear());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticElectionVotes.remove(optionText));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _handleCustomOptionVote(CustomOption customOption) async {
    if (widget.userId == null) return;

    try {
      final controller = ref.read(surveysControllerProvider);
      await controller.voteOnCustomOption(customOption.documentId);
      final updatedSurvey = await controller.fetchSurveyById(
        widget.surveyEntry.documentId,
      );
      ref
          .read(surveysListProvider.notifier)
          .markVotedInSession(widget.surveyEntry.documentId);
      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);
    } catch (e) {
      if (mounted) {
        final message =
            e is AppException ? e.message : 'Ein Fehler ist aufgetreten.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _handleApproveCustomOption(CustomOption option) =>
      _handleReviewCustomOption(
        option,
        review: (controller) =>
            controller.approveCustomOption(option.documentId),
        successMessage: 'Antwort freigegeben',
      );

  Future<void> _handleRejectCustomOption(CustomOption option) =>
      _handleReviewCustomOption(
        option,
        review: (controller) =>
            controller.rejectCustomOption(option.documentId),
        successMessage: 'Antwort abgelehnt',
      );

  Future<void> _handleReviewCustomOption(
    CustomOption option, {
    required Future<CustomOption> Function(dynamic controller) review,
    required String successMessage,
  }) async {
    setState(() => _optimisticallyHandledPendingDocIds.add(option.documentId));

    try {
      final controller = ref.read(surveysControllerProvider);
      await review(controller);
      final updatedSurvey =
          await controller.fetchSurveyById(widget.surveyEntry.documentId);
      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);

      if (mounted) {
        setState(
          () => _optimisticallyHandledPendingDocIds.remove(option.documentId),
        );
        _showReviewSnackbar(
          successMessage,
          () => _undoCustomOptionReview(option),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _optimisticallyHandledPendingDocIds.remove(option.documentId),
        );
        final message =
            e is AppException ? e.message : 'Ein Fehler ist aufgetreten.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _undoCustomOptionReview(CustomOption option) async {
    try {
      final controller = ref.read(surveysControllerProvider);
      await controller.undoCustomOptionReview(option.documentId);
      final updatedSurvey =
          await controller.fetchSurveyById(widget.surveyEntry.documentId);
      ref.read(surveysListProvider.notifier).updateSurveyInList(updatedSurvey);
    } catch (e) {
      if (mounted) {
        final message =
            e is AppException ? e.message : 'Rückgängig nicht möglich.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _showReviewSnackbar(String message, VoidCallback onUndo) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    const displayDuration = Duration(seconds: 5);
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Rückgängig', onPressed: onUndo),
        duration: displayDuration,
      ),
    );
    // Flutter überspringt seinen Auto-Hide-Timer, wenn accessibleNavigation
    // aktiv ist und ein SnackBarAction gesetzt ist. Eigener Timer als Fallback.
    Future.delayed(displayDuration, controller.close);
  }

  VoidCallback? _resolveOptionTap(
    SurveyOption option,
    SurveyStatus status,
    bool hasVoted,
  ) {
    final isElection = widget.surveyEntry.type == SurveyType.election;
    final isOptionAlreadyVoted = isElection &&
        (_optimisticElectionVotes.contains(option.text) ||
            option.currentUserVoted);

    if (widget.userId == null) return widget.onLoginRequired;
    if (_isAdminBlocked) return () => showAdminBlockedDialog(context);
    if (status == SurveyStatus.expired) return () => showExpiredDialog(context);
    if (hasVoted) return () => showAlreadyVotedDialog(context);
    if (isOptionAlreadyVoted) return null;
    if (isElection) return () => _handleElectionVote(option.text);
    return () => _handleMultipleChoiceVote(option.text);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.surveyEntry.getStatus(widget.userId);

    final hasVoted = switch (widget.surveyEntry.type) {
      SurveyType.election => () {
          if (widget.userId == null) return false;
          final serverVotes = widget.surveyEntry.options
                  ?.where((o) => o.currentUserVoted)
                  .length ??
              0;
          return (serverVotes + _optimisticElectionVotes.length) >=
              widget.surveyEntry.maxVotes;
        }(),
      SurveyType.yesNo => _optimisticYesNoVote != null ||
          (widget.userId != null &&
              widget.surveyEntry.hasUserVoted(widget.userId!)),
      SurveyType.multiple => _optimisticMultipleChoiceVote != null ||
          (widget.userId != null &&
              widget.surveyEntry.hasUserVoted(widget.userId!)),
    };

    final showResults = switch (widget.surveyEntry.type) {
      SurveyType.election => status == SurveyStatus.expired,
      SurveyType.yesNo ||
      SurveyType.multiple =>
        hasVoted || status == SurveyStatus.expired,
    };

    VoidCallback? yesNoTapHandler(bool voteYes) {
      if (status == SurveyStatus.expired) {
        return () => showExpiredDialog(context);
      }
      if (hasVoted) return () => showAlreadyVotedDialog(context);
      if (widget.userId == null) return widget.onLoginRequired;
      return () => _handleYesNoVote(voteYes);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showMedia &&
              (widget.surveyEntry.imageUrl != null ||
                  widget.surveyEntry.type == SurveyType.election))
            SurveyCardImage(surveyEntry: widget.surveyEntry),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: widget.surveyEntry.type == SurveyType.yesNo
                ? SurveyYesNoContent(
                    surveyEntry: widget.surveyEntry,
                    status: status,
                    hasVoted: hasVoted,
                    showResults: showResults,
                    isNew: widget.isNew,
                    optimisticVote: _optimisticYesNoVote,
                    userId: widget.userId,
                    onVoteYes: yesNoTapHandler(true),
                    onVoteNo: yesNoTapHandler(false),
                  )
                : SurveyMultipleChoiceContent(
                    surveyEntry: widget.surveyEntry,
                    status: status,
                    hasVoted: hasVoted,
                    showResults: showResults,
                    isNew: widget.isNew,
                    isAdminBlocked: _isAdminBlocked,
                    isJUPAdmin: widget.isJUPAdmin,
                    userId: widget.userId,
                    optimisticVote: _optimisticMultipleChoiceVote,
                    optimisticElectionVotes: _optimisticElectionVotes,
                    optimisticallyHandledPendingDocIds:
                        _optimisticallyHandledPendingDocIds,
                    onOptionTap: (option) =>
                        _resolveOptionTap(option, status, hasVoted),
                    onCustomOptionTap: widget.userId != null
                        ? () => CustomOptionSheet.show(
                            context, widget.surveyEntry.documentId,
                            isJUPAdmin: widget.isJUPAdmin)
                        : widget.onLoginRequired,
                    onCustomOptionVoteTap: (customOption) {
                      if (widget.userId == null) return widget.onLoginRequired;
                      if (status == SurveyStatus.expired) {
                        return () => showExpiredDialog(context);
                      }
                      if (hasVoted) {
                        return () => showAlreadyVotedDialog(context);
                      }
                      return () => _handleCustomOptionVote(customOption);
                    },
                    onApproveCustomOption: _handleApproveCustomOption,
                    onRejectCustomOption: _handleRejectCustomOption,
                  ),
          ),
          if (widget.surveyEntry.type == SurveyType.election)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: BodyMedium(
                  text:
                      '${widget.surveyEntry.totalVotes} ${widget.surveyEntry.totalVotes == 1 ? 'Vote' : 'Votes'}',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            CommentSection(
              documentId: widget.surveyEntry.documentId,
              comments: widget.surveyEntry.comments,
              voteCount: widget.surveyEntry.totalVotes,
              disabled: status == SurveyStatus.expired,
              onSubmitComment:
                  (documentId, text, userId, currentComments) async {
                final controller = ref.read(surveysControllerProvider);
                final updatedSurvey = await controller.addComment(
                  documentId,
                  text,
                  userId,
                  currentComments,
                );
                ref
                    .read(surveysListProvider.notifier)
                    .updateSurveyInList(updatedSurvey);
              },
              onDeleteComment: (documentId, commentId, currentComments) async {
                final controller = ref.read(surveysControllerProvider);
                final updatedSurvey = await controller.deleteComment(
                  documentId,
                  commentId,
                  currentComments,
                );
                ref
                    .read(surveysListProvider.notifier)
                    .updateSurveyInList(updatedSurvey);
              },
            ),
        ],
      ),
    );
  }
}
