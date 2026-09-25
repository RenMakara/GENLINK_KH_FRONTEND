import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('GenLinkConfirmDialog Tests', () {
    testWidgets('renders title, message, and action buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const GenLinkConfirmDialog(
            type: GenLinkDialogType.danger,
            title: 'Delete Event?',
            message: 'Are you sure you want to delete this event? This action cannot be undone.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
          ),
        ),
      );

      expect(find.text('Delete Event?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this event? This action cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('shows danger semantic styling and default delete icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const GenLinkConfirmDialog(
            type: GenLinkDialogType.danger,
            title: 'Delete Item?',
            message: 'This will permanently remove the item.',
          ),
        ),
      );

      // Icon should be delete_outline_rounded by default for danger
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('shows discard semantic styling and description icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const GenLinkConfirmDialog(
            type: GenLinkDialogType.discard,
            title: 'Discard Draft?',
            message: 'You have unsaved changes. Discard them?',
            cancelLabel: 'Keep Editing',
            confirmLabel: 'Discard',
          ),
        ),
      );

      expect(find.text('Discard Draft?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('single action mode only displays confirm button', (tester) async {
      bool confirmTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: GenLinkConfirmDialog(
            type: GenLinkDialogType.success,
            title: 'Changes Saved!',
            message: 'Your changes have been saved successfully.',
            confirmLabel: 'OK',
            isSingleAction: true,
            onConfirm: () {
              confirmTapped = true;
            },
          ),
        ),
      );

      expect(find.text('Changes Saved!'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(confirmTapped, isTrue);
    });

    testWidgets('tapping cancel executes onCancel and pops false via show helper',
        (tester) async {
      bool? result;
      bool onCancelCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await GenLinkConfirmDialog.show(
                    context: context,
                    type: GenLinkDialogType.danger,
                    title: 'Delete Task?',
                    message: 'Are you sure?',
                    cancelLabel: 'Cancel',
                    confirmLabel: 'Delete',
                    onCancel: () {
                      onCancelCalled = true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Task?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(onCancelCalled, isTrue);
      expect(find.text('Delete Task?'), findsNothing);
    });

    testWidgets('tapping confirm executes onConfirm and pops true via show helper',
        (tester) async {
      bool? result;
      bool onConfirmCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await GenLinkConfirmDialog.showDanger(
                    context: context,
                    title: 'Delete Goal?',
                    message: 'Are you sure you want to delete this goal?',
                    cancelLabel: 'Cancel',
                    confirmLabel: 'Delete',
                    onConfirm: () {
                      onConfirmCalled = true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Goal?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(onConfirmCalled, isTrue);
      expect(find.text('Delete Goal?'), findsNothing);
    });

    testWidgets('tapping close X button executes onCancel and pops false', (tester) async {
      bool? result;
      bool onCancelCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await GenLinkConfirmDialog.show(
                    context: context,
                    type: GenLinkDialogType.info,
                    title: 'Are you sure?',
                    message: 'Please review before continuing.',
                    onCancel: () {
                      onCancelCalled = true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(onCancelCalled, isTrue);
      expect(find.text('Are you sure?'), findsNothing);
    });

    testWidgets('renders cleanly in dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          themeMode: ThemeMode.dark,
          child: const GenLinkConfirmDialog(
            type: GenLinkDialogType.danger,
            title: 'Delete Event?',
            message: 'Are you sure you want to delete this event? This action cannot be undone.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
          ),
        ),
      );

      expect(find.text('Delete Event?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('renders long Khmer text without overflow on a small screen',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const GenLinkConfirmDialog(
            type: GenLinkDialogType.warning,
            title: 'តើអ្នកប្រាកដជាចង់បោះបង់ការផ្លាស់ប្តូរដែលមិនទាន់រក្សាទុកឬ?',
            message:
                'ការផ្លាស់ប្តូរទាំងអស់ដែលអ្នកបានបញ្ចូលនឹងត្រូវបាត់បង់ជារៀងរហូត ប្រសិនបើអ្នកចាកចេញពីទំព័រនេះឥឡូវនេះ។',
            cancelLabel: 'បន្តការកែសម្រួល',
            confirmLabel: 'បោះបង់',
          ),
        ),
      );

      expect(
        find.text('តើអ្នកប្រាកដជាចង់បោះបង់ការផ្លាស់ប្តូរដែលមិនទាន់រក្សាទុកឬ?'),
        findsOneWidget,
      );
      expect(find.text('បន្តការកែសម្រួល'), findsOneWidget);
      expect(find.text('បោះបង់'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
