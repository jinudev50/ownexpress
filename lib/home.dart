import 'package:flutter/material.dart';
import 'package:ownexpense/profile/profile.dart';
import 'package:ownexpense/services/support_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ownexpense/services/supabase_image_service.dart';
import 'dart:math' as math;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  Map<String, double> _categoryTotals = {};
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _profileImageUrl;

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
    _loadProfileImage();
  }
  
  Future<void> _loadProfileImage() async {
    try {
      final imageUrl = await SupabaseImageService.getUserProfileImage();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _profileImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error loading profile image in home: $e');
    }
  }

  void _fetchFinancialData() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('ERROR: No user logged in');
      return;
    }

    debugPrint('Fetching data for user: $userId');
    debugPrint('Current user: ${FirebaseAuth.instance.currentUser?.displayName}');

    // Fetch expense data from user's expenses subcollection
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {
      debugPrint('Expense snapshot received with ${snapshot.docs.length} documents');
      
      double expense = 0.0;
      Map<String, double> categoryTotals = {};
      
      for (var doc in snapshot.docs) {
        double amount = doc['amount']?.toDouble() ?? 0.0;
        String category = doc['category'] ?? 'Other';
        String docDate = doc['date'] ?? '';
        String userName = doc['userName'] ?? 'User';
        
        debugPrint('Processing expense doc: amount=$amount, category=$category, date=$docDate, userName=$userName');
        debugPrint('Full doc data: ${doc.data()}');
        
        // Filter by selected month and year
        if (_isDateInSelectedPeriod(docDate)) {
          expense += amount;
          
          // Calculate category totals
          categoryTotals[category] =
              (categoryTotals[category] ?? 0) + amount;
          
          debugPrint('Category $category updated: ${categoryTotals[category]}');
        }
      }
      
      setState(() {
        _totalExpense = expense;
        _categoryTotals = categoryTotals;
        debugPrint('Total expense updated: $expense');
        debugPrint('Category totals: $_categoryTotals');
      });
    });

    // Fetch income data from user's income subcollection
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .snapshots()
        .listen((snapshot) {
      debugPrint('Income snapshot received with ${snapshot.docs.length} documents');
      
      double income = 0.0;
      
      for (var doc in snapshot.docs) {
        double amount = doc['amount']?.toDouble() ?? 0.0;
        String docDate = doc['date'] ?? '';
        String userName = doc['userName'] ?? 'User';
        
        debugPrint('Processing income doc: amount=$amount, date=$docDate, userName=$userName');
        debugPrint('Full doc data: ${doc.data()}');
        
        // Filter by selected month and year
        if (_isDateInSelectedPeriod(docDate)) {
          income += amount;
          debugPrint('Income added: $amount');
        }
      }
      
      setState(() {
        _totalIncome = income;
        debugPrint('Total income updated: $income');
      });
    });
  }

  bool _isDateInSelectedPeriod(String dateStr) {
    if (dateStr.isEmpty) return false;
    
    debugPrint('Checking date: "$dateStr" for selected month: $_selectedMonth, year: $_selectedYear');
    
    try {
      DateTime docDate;
      
      // Try different date formats
      if (dateStr.contains('T')) {
        // ISO format with time: "2026-03-10T15:22:22.000Z"
        docDate = DateTime.parse(dateStr);
      } else if (dateStr.contains('-')) {
        // Try parsing YYYY-MM-DD format
        docDate = DateTime.parse(dateStr);
      } else {
        // Try other formats or use current date as fallback
        docDate = DateTime.tryParse(dateStr) ?? DateTime.now();
      }
      
      debugPrint('Successfully parsed date: $docDate (month: ${docDate.month}, year: ${docDate.year})');
      
      return docDate.month == _selectedMonth && docDate.year == _selectedYear;
    } catch (e) {
      debugPrint('Error parsing date "$dateStr": $e');
      return false;
    }
  }

  void _updateSelectedMonth(int month) {
    setState(() {
      _selectedMonth = month;
    });
    _fetchFinancialData();
  }

  void _updateSelectedYear(int year) {
    setState(() {
      _selectedYear = year;
    });
    _fetchFinancialData();
  }

  List<String> _getMonths() {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }

  List<int> _getYears() {
    List<int> years = [];
    int currentYear = DateTime.now().year;
    for (int i = currentYear - 5; i <= currentYear + 5; i++) {
      years.add(i);
    }
    return years;
  }

  String _formatDateRange() {
    String selectedMonth = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][_selectedMonth - 1];
    
    // Get the last day of selected month
    DateTime lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    
    return "1 ${selectedMonth} ${_selectedYear} - ${lastDay.day} ${selectedMonth} ${_selectedYear}";
  }

  Widget _buildDynamicLegend() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    if (_categoryTotals.isEmpty) {
      return Column(
        children: [_buildLegendItem("No Data", "0%", "₹0", Colors.grey, isSmallScreen)],
      );
    }

    List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    List<Widget> legendItems = [];
    int colorIndex = 0;

    _categoryTotals.forEach((category, amount) {
      double percentage = _totalExpense > 0
          ? (amount / _totalExpense) * 100
          : 0;
      Color color = colors[colorIndex % colors.length];

      legendItems.add(
        _buildLegendItem(
          category,
          "${percentage.toStringAsFixed(1)}%",
          "₹${amount.toStringAsFixed(2)}",
          color,
          isSmallScreen,
        ),
      );

      if (legendItems.length < _categoryTotals.length) {
        legendItems.add(SizedBox(height: isSmallScreen ? 6 : 8));
      }

      colorIndex++;
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: legendItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            margin: EdgeInsets.only(top: 20, left: 25, right: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                bool isMobile = screenWidth < 600;

                return Column(
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back",
                              style: TextStyle(fontSize: isMobile ? 16 : 20),
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  "User",
                              style: AppWidget.healineTextStyle(
                                isMobile ? 28 : 34,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // IconButton(
                            //   icon: Icon(
                            //     Icons.logout,
                            //     color: Colors.red,
                            //     size: isMobile ? 20 : 24,
                            //   ),
                            //   onPressed: _logout,
                            // ),
                            SizedBox(width: isMobile ? 8 : 10),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => profile()),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: _profileImageUrl != null
                                    ? Image.network(
                                        _profileImageUrl!,
                                        width: isMobile ? 60 : 70,
                                        height: isMobile ? 60 : 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.person,
                                              size: isMobile ? 30 : 40,
                                              color: Colors.grey.shade400,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        "assets/images/boy1.jpg",
                                        width: isMobile ? 60 : 70,
                                        height: isMobile ? 60 : 70,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 10 : 15),
                    // Title Section
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Manage Your \n Expense",
                              textAlign: TextAlign.center,
                              style: AppWidget.healineTextStyle(
                                isMobile ? 28 : 34,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 15 : 20),
                    Container(
                      margin: EdgeInsets.only(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            spreadRadius: 2,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Expenses",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isMobile ? 20 : 24,
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade400, Colors.red.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "₹${_totalExpense.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 16 : 20,
                                      color: Colors.white,
                                      shadows: isMobile ? [] : [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _formatDateRange(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),

                            SizedBox(
                              height: isMobile ? 120 : 150,
                              child: Row(
                                children: [
                                  // Donut Chart
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.grey.shade100, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 15,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: CustomPaint(
                                        painter: DynamicDonutChartPainter(
                                          _categoryTotals,
                                          _totalExpense,
                                        ),
                                        child: SizedBox(width: isMobile ? 100 : 150, height: isMobile ? 100 : 150),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Legend
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.grey.shade50, Colors.white],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade200),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: _buildDynamicLegend(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        // This Month Button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                              child: Text(
                                "This Month",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isMobile ? 12 : 15,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // This Year Button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade100, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                              child: Text(
                                "This Year",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isMobile ? 12 : 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        // Month Selector
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: DropdownButton<int>(
                                value: _selectedMonth,
                                dropdownColor: Colors.red.shade500,
                                icon: Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isMobile ? 12 : 15),
                                items: _getMonths().asMap().entries.map((entry) {
                                  return DropdownMenuItem<int>(
                                    value: entry.key + 1,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(entry.value, style: TextStyle(color: Colors.black, fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    _updateSelectedMonth(newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Year Selector
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade100, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                              child: DropdownButton<int>(
                                value: _selectedYear,
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.date_range, color: Colors.red.shade600, size: 20),
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: isMobile ? 12 : 15),
                                items: _getYears().map((year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString(), style: TextStyle(color: Colors.black, fontSize: isMobile ? 12 : 14)),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    _updateSelectedYear(newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        // Income Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.green.shade300, width: 2),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 15.0 : 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.trending_up, color: Colors.green.shade600, size: isMobile ? 20 : 24),
                                      SizedBox(width: 8),
                                      Text(
                                        "Income",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isMobile ? 14 : 17,
                                          color: Colors.green.shade700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green.shade400, Colors.green.shade600],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "+₹${_totalIncome.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 14 : 17,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 10 : 15),
                                  Container(
                                    height: isMobile ? 6 : 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green.shade300, Colors.green.shade500],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        // Expense Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.red.shade300, width: 2),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 15.0 : 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.trending_down, color: Colors.red.shade600, size: isMobile ? 20 : 24),
                                      SizedBox(width: 8),
                                      Text(
                                        "Expense",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isMobile ? 14 : 17,
                                          color: Colors.red.shade700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.red.shade400, Colors.red.shade600],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "-₹${_totalExpense.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 14 : 17,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 10 : 15),
                                  Container(
                                    height: isMobile ? 6 : 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.red.shade300, Colors.red.shade500],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 20 : 25),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: isMobile ? 30 : 40,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                              child: Text(
                                "Your expense plan looks good",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String category,
    String percentage,
    String amount,
    Color color,
    bool isSmallScreen,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 8 : 10,
          height: isSmallScreen ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Expanded(
          flex: 2,
          child: Text(
            category,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        SizedBox(width: isSmallScreen ? 2 : 4),
        Text(
          percentage,
          style: TextStyle(
            fontSize: isSmallScreen ? 9 : 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Expanded(
          child: Text(
            amount,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class DynamicDonutChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double totalExpense;

  DynamicDonutChartPainter(this.categoryTotals, this.totalExpense);

  @override
  void paint(Canvas canvas, Size size) {
    if (categoryTotals.isEmpty || totalExpense == 0) {
      _drawEmptyChart(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.6;

    final paint = Paint()..style = PaintingStyle.fill;

    List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    double startAngle = -math.pi / 2;
    int colorIndex = 0;

    categoryTotals.forEach((category, amount) {
      double percentage = totalExpense > 0 ? (amount / totalExpense) : 0;
      double sweepAngle = percentage * 2 * math.pi;

      paint.color = colors[colorIndex % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    });

    // Draw inner circle to create donut effect
    paint.color = Colors.white;
    canvas.drawCircle(center, innerRadius, paint);
  }

  void _drawEmptyChart(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.6;

    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.grey[300]!;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      0,
      2 * math.pi,
      true,
      paint,
    );

    paint.color = Colors.white;
    canvas.drawCircle(center, innerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
