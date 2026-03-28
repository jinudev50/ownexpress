
import 'package:flutter/material.dart';
import 'package:ownexpense/login.dart';
import 'package:ownexpense/services/support_widget.dart';


class onboardingr extends StatefulWidget {
  const onboardingr({super.key});

  @override
  State<onboardingr> createState() => _onboardingrState();
}

class _onboardingrState extends State<onboardingr> {
  @override
  // void initState() {
  //   super.initState();
  //   Timer(const Duration(seconds: 3), () {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => login()),
  //     );
  //   });
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8edc2),
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 80),
            Image.asset("assets/images/onboard.png"),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 15,
                  right: 15,
                  bottom: 15,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      Text(
                        "Manage your daily\nlife Expense",
                        textAlign: TextAlign.center,
                        style: AppWidget.healineTextStyle(34),
                      ),
                      SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Text(
                          "Expenese tracker is a simple and efficient personal finance management app that allows you to track daily expense and income",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: Material(
                          elevation: 3,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                                bottom: 10,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => login(),
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Text(
                                    "Let's Started",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
