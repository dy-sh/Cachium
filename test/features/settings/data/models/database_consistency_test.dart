import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/settings/data/models/database_consistency.dart';

void main() {
  group('ConsistencyCheck', () {
    test('hasIssues returns true when count > 0', () {
      const check = ConsistencyCheck(
        label: 'test',
        count: 3,
        icon: Icons.error,
      );
      expect(check.hasIssues, isTrue);
    });

    test('hasIssues returns false when count is 0', () {
      const check = ConsistencyCheck(
        label: 'test',
        count: 0,
        icon: Icons.check,
      );
      expect(check.hasIssues, isFalse);
    });
  });

  group('DatabaseConsistency.isConsistent', () {
    test('true when all counts are zero', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 0,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      expect(dc.isConsistent, isTrue);
    });

    test('false when any count is non-zero', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 1,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      expect(dc.isConsistent, isFalse);
    });

    test('false when optional count is non-zero', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 0,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
        budgetsWithInvalidCategory: 2,
      );
      expect(dc.isConsistent, isFalse);
    });
  });

  group('DatabaseConsistency.totalIssues', () {
    test('sums all issue counts', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 1,
        transactionsWithInvalidAccount: 2,
        categoriesWithInvalidParent: 3,
        accountsWithIncorrectBalance: 4,
        duplicateTransactions: 5,
        budgetsWithInvalidCategory: 6,
        savingsGoalsWithInvalidAccount: 7,
        rulesWithInvalidReferences: 8,
        templatesWithInvalidReferences: 9,
      );
      expect(dc.totalIssues, 45);
    });

    test('returns 0 when all clean', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 0,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      expect(dc.totalIssues, 0);
    });
  });

  group('DatabaseConsistency.allChecks', () {
    test('returns 9 checks', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 0,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      expect(dc.allChecks.length, 9);
    });

    test('check counts match constructor values', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 3,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 1,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 2,
      );
      final checks = dc.allChecks;
      expect(checks[0].count, 3); // invalid category
      expect(checks[1].count, 0); // invalid account
      expect(checks[2].count, 2); // duplicates
      expect(checks[3].count, 1); // invalid parent
    });
  });

  group('DatabaseConsistency.issueChecks', () {
    test('filters to only checks with issues', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 3,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 1,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      final issues = dc.issueChecks;
      expect(issues.length, 2);
      expect(issues.every((c) => c.count > 0), isTrue);
    });

    test('returns empty list when all clean', () {
      const dc = DatabaseConsistency(
        transactionsWithInvalidCategory: 0,
        transactionsWithInvalidAccount: 0,
        categoriesWithInvalidParent: 0,
        accountsWithIncorrectBalance: 0,
        duplicateTransactions: 0,
      );
      expect(dc.issueChecks, isEmpty);
    });
  });
}
