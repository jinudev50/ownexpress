import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ownexpense/profile/profile.dart';

class AddIncome extends StatefulWidget {
  const AddIncome({super.key});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {
  late FocusNode _amountFocusNode;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter amount')),
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
          .collection('income')
          .add({
            'amount': double.parse(_amountController.text),
            'date': _selectedDate.toString(),
            'createdAt': Timestamp.now(),
            'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income added successfully!')),
      );

      _amountController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding income: $e')),
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
          "Add Income",
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
                    "assets/images/income.png",
                    width: isMobile ? screenWidth * 0.4 : 200,
                    height: isMobile ? screenWidth * 0.4 : 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 15 : 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter Amount",
                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
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
                      ? Border.all(color: Colors.green, width: 2)
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: isMobile ? 8 : 12),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 15),
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      height: isMobile ? 30 : 35,
                      width: isMobile ? 30 : 35,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Icon(Icons.calendar_month, color: Colors.white, size: isMobile ? 16 : 20),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _selectedDate.toString().split(' ')[0],
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 20 : 25),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.white),
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