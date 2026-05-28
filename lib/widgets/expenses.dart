import 'dart:convert';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = SharedPreferencesAsync();
    final jsonString = await prefs.getString('expenses');
    if (jsonString == null) return;
    final List<dynamic> jsonList = jsonDecode(jsonString);
    setState(() {
      _registeredExpenses.clear();
      _registeredExpenses.addAll(
        jsonList.map((e) => Expense.fromJson(e as Map<String, dynamic>)),
      );
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = SharedPreferencesAsync();
    final jsonString =
        jsonEncode(_registeredExpenses.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', jsonString);
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
    _saveExpenses();
  }

  void _removeExpense(Expense expense) {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    _saveExpenses();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Xarajat o\'chirildi'),
        action: SnackBarAction(
          label: 'Bekor qilish',
          onPressed: () {
            setState(() {
              _registeredExpenses.insert(expenseIndex, expense);
            });
            _saveExpenses();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget mainContent = const Center(
      child: Text('Hali xarajat yo\'q. Yangi xarajat qo\'shing!'),
    );

    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xarajat hisoblagich'),
        actions: [
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: screenWidth < 600
          ? Column(
              children: [
                Chart(expenses: _registeredExpenses),
                Expanded(child: mainContent),
              ],
            )
          : Row(
              children: [
                Expanded(child: Chart(expenses: _registeredExpenses)),
                Expanded(child: mainContent),
              ],
            ),
    );
  }
}
