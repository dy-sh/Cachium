import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../providers/attachments_provider.dart';

class AttachmentViewerScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final int initialIndex;

  const AttachmentViewerScreen({
    super.key,
    required this.transactionId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<AttachmentViewerScreen> createState() =>
      _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState
    extends ConsumerState<AttachmentViewerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(
        attachmentsForTransactionProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return Column(
                children: [
                  FormHeader(
                    title: 'Attachments',
                    onClose: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No attachments',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                FormHeader(
                  title:
                      '${widget.initialIndex + 1} of ${attachments.length}',
                  onClose: () => context.pop(),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      final file = File(attachment.filePath);

                      if (!file.existsSync()) {
                        return const Center(
                          child: Text(
                            'File not found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error loading attachments',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
