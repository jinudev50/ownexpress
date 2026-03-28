import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ownexpense/profile/profile.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late FocusNode _amountFocusNode;
  late TextEditingController _amountController;
  bool _isAmountFocused = false;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();
    _amountFocusNode.addListener(() {
      setState(() {
        _isAmountFocused = _amountFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _showCategoryDialog() {
    List<String> categories = [
      'Shopping',
      'Food',
      'Game',
      'Transport',
      'Entertainment',
      'Bills',
      'Healthcare',
      'Education',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Category',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    title: Text(
                      categories[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _selectedCategory == categories[index]
                        ? Icon(Icons.check, color: Colors.red)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = categories[index];
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill amount and select category')),
      );
      return;
    }

    // Amount validation: minimum ₹10 and maximum ₹5000
    double amount = double.parse(_amountController.text);
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum amount is ₹10')),
      );
      return;
    }

    if (amount > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum amount is ₹5000')),
      );
      return;
    }

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .add({
            'amount': double.parse(_amountController.text),
            'category': _selectedCategory,
            'date': _selectedDate.toString(),
            'createdAt': Timestamp.now(),
            'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense added successfully!')),
      );

      _amountController.clear();
      setState(() {
        _selectedCategory = null;
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: isMobile ? 2.0 : 5.0),
          child: Container(
            width: isMobile ? 8 : 10,
            height: isMobile ? 8 : 10,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: isMobile ? 20 : 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => profile()),
                );
              },
            ),
          ),
        ),
        title: Text(
          "Add Expense",
          style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 15.0 : 20.0),
          child: Column(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "assets/images/expense.png",
                    width: isMobile ? screenWidth * 0.4 : 200,
                    height: isMobile ? screenWidth * 0.4 : 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter Amount",
                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: _amountController.text.isNotEmpty
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: "Enter amount",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: isMobile ? 12 : 15),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 15 : 20),
              GestureDetector(
                onTap: () {
                  _showCategoryDialog();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: isMobile ? 15 : 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory ?? "Select Category",
                          style: TextStyle(
                            color: _selectedCategory != null ? Colors.black : Colors.grey,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 15 : 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      height: isMobile ? 35 : 40,
                      width: isMobile ? 35 : 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Icon(Icons.calendar_month, color: Colors.white, size: isMobile ? 20 : 24),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _selectedDate.toString().split(' ')[0],
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 25 : 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}