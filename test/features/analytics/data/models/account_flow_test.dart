import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/analytics/data/models/account_flow.dart';
import 'package:cachium/features/analytics/data/models/sankey_flow.dart';

void main() {
  group('AccountFlowData.isEmpty', () {
    test('true when both lists empty', () {
      const data = AccountFlowData(
        incomeNodes: [],
        expenseNodes: [],
        totalIncome: 0,
        totalExpense: 0,
      );
      expect(data.isEmpty, isTrue);
    });

    test('false when incomeNodes non-empty', () {
      const data = AccountFlowData(
        incomeNodes: [
          FlowNode(
            id: 'n1',
            label: 'Salary',
            color: Colors.green,
            amount: 5000,
            percentage: 100,
          ),
        ],
        expenseNodes: [],
        totalIncome: 5000,
        totalExpense: 0,
      );
      expect(data.isEmpty, isFalse);
    });

    test('false when expenseNodes non-empty', () {
      const data = AccountFlowData(
        incomeNodes: [],
        expenseNodes: [
          FlowNode(
            id: 'n1',
            label: 'Food',
            color: Colors.red,
            amount: 500,
            percentage: 100,
          ),
        ],
        totalIncome: 0,
        totalExpense: 500,
      );
      expect(data.isEmpty, isFalse);
    });
  });

  group('SankeyData.isEmpty', () {
    test('true when both source and target empty', () {
      const data = SankeyData(
        sourceNodes: [],
        targetNodes: [],
        links: [],
      );
      expect(data.isEmpty, isTrue);
    });

    test('false when sourceNodes non-empty', () {
      const data = SankeyData(
        sourceNodes: [
          SankeyNode(id: 's1', label: 'Income', color: Colors.green, amount: 100),
        ],
        targetNodes: [],
        links: [],
      );
      expect(data.isEmpty, isFalse);
    });

    test('false when targetNodes non-empty', () {
      const data = SankeyData(
        sourceNodes: [],
        targetNodes: [
          SankeyNode(id: 't1', label: 'Expense', color: Colors.red, amount: 50),
        ],
        links: [],
      );
      expect(data.isEmpty, isFalse);
    });
  });
}
