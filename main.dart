// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClickerGame(),
      // theme: new ThemeData(scaffoldBackgroundColor: Color.fromARGB(255, 46, 76, 197)),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClickerGame extends StatefulWidget {
  @override
  _ClickerGameState createState() => _ClickerGameState();
}

class _ClickerGameState extends State<ClickerGame> {
  int points = 0; // Starting points
  GlobalKey _key = GlobalKey();

  // Tap upgrade
  int clickValue = 1000000; // Starting click value
  int upgradeCost = 100; // First tap upgrade cost
  List<String> cpuList = [
    'I3-2120', 'i3-3150', 'i3-4010', 'i5-5040', // Need more CPUs
  ];
  int cpuLevel = 0; // index of the current CPU in the list

  // Passive points upgrade
  int passiveClicks = 0;
  int passiveClickCost = 500;
  Timer? passiveClickTimer;
  int totalPointsEarned = 0;
  List<String> gpuList = [
    'RTX4050',
    'RTX2050',
    'RTX1050',
    'RTX1060',
  ];
  int gpuLevel = 0;

  // Double tap powerup
  bool doubleClickPowerActive = false;
  int doubleClickPowerCost = 500;
  Timer? doubleClickPowerTimer;

  // Combo multiplier
  int comboCount = 0;
  int comboMultiplier = 1;
  int clicksPerBonus = 20;
  int lessClicksPerBonusCost = 500;
  int multiplierCost = 500;
  int maxBonusMultiplier = 5;
  Timer? comboTimer;

  // Divisions
  int currentDivisionCost = 10000;
  int divisionMultiplier = 3;
  String currentDivision = 'Budget Builder';

  String currentLogo = "images/logo.png";

  void showPointsPopup(int earnedPoints) {
    OverlayEntry overlayEntry;

    // Find the position of the tapped widget
    RenderBox renderBox = _key.currentContext?.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);

    // Generate a random offset within the screen size
    double screenWidth = MediaQuery.of(context).size.width;
    //double screenHeight = MediaQuery.of(context).size.height;
    double randomX = Random().nextInt(screenWidth.toInt()).toDouble();
    //double randomY = Random().nextInt(screenHeight.toInt()).toDouble();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy,
        left: randomX,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 50),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8),
              child: Text(
                doubleClickPowerActive ? '+${clickValue * 2}' : '+$clickValue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Schedule a timer to remove the overlay after 0.5 seconds
    Timer(Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  }

  void handleClick() {
    setState(() {
      if (doubleClickPowerActive) {
        points += 2 * clickValue * comboMultiplier;
        showPointsPopup(2 * comboMultiplier);
        saveGameState();
      } else {
        points += clickValue;
        showPointsPopup(1);
        saveGameState();
      }

      comboCount++;

      // Combo streak
      if (comboCount >= clicksPerBonus) {
        int bonusPoints = 1;

        if (comboMultiplier <= maxBonusMultiplier) {
          bonusPoints = comboMultiplier;
        } else {
          bonusPoints = maxBonusMultiplier;
        }

        points += bonusPoints;
        showComboDialog(bonusPoints);

        comboCount = 0;
        comboMultiplier++;

        // Restart the combo timer
        restartComboTimer();
      }
    });
  }

  void restartComboTimer() {
    // Cancel the existing timer
    comboTimer?.cancel();

    // Starts a new timer to reset combo after 5 seconds of inactivity
    comboTimer = Timer(Duration(seconds: 5), () {
      setState(() {
        comboCount = 0;
        comboMultiplier = 1;
      });
    });
  }

  @override
  void dispose() {
    comboTimer?.cancel();
    passiveClickTimer?.cancel();
    saveGameState();
    super.dispose();
  }

  // Tap upgrade function
  void buyUpgrade() {
    if (points >= upgradeCost) {
      setState(() {
        points -= upgradeCost;
        clickValue += 1;
        upgradeCost += (0.5 * upgradeCost).round();;
        // Increases the CPU when upgrade is bought
        cpuLevel = (cpuLevel + 1) % cpuList.length;
        saveGameState();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content: Text("You need $upgradeCost points to buy the upgrade."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadGameState();
    // Initialize the timer in the initState or when the widget is created
    passiveClickTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      // Calculate points based on the number of upgrades but only add them once
      int pointsToAdd = passiveClicks;
      totalPointsEarned += pointsToAdd;

      setState(() {
        points += pointsToAdd;
      });
    });
  }

  // Save the game state to SharedPreferences
  Future<void> saveGameState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('points', points);
    prefs.setInt('clickValue', clickValue);
    prefs.setInt('gpuLevel', gpuLevel);
    prefs.setInt('passiveClickCost', passiveClickCost);

    prefs.setInt('upgradeCost', upgradeCost);
    prefs.setInt('cpuLevel', cpuLevel);
    prefs.setInt('passiveClicks', passiveClicks);
    prefs.setInt('doubleClickPowerCost', doubleClickPowerCost);
    prefs.setInt('clicksPerBonus', clicksPerBonus);
    prefs.setInt('lessClicksPerBonusCost', lessClicksPerBonusCost );
    prefs.setInt('multiplierCost', multiplierCost );

    prefs.setInt('currentDivisionCost', currentDivisionCost  );
    prefs.setString('currentDivision', currentDivision);
    prefs.setString('currentLogo', currentLogo  );
    prefs.setInt('multiplierCost', multiplierCost );
    // Add other variables you want to save here
  }

  // Load the game state from SharedPreferences
  Future<void> loadGameState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      points = prefs.getInt('points') ?? points;
      clickValue = prefs.getInt('clickValue') ?? clickValue;
      gpuLevel = prefs.getInt('gpuLevel') ?? gpuLevel;
      passiveClickCost = prefs.getInt('passiveClickCost') ?? passiveClickCost;    
      upgradeCost = prefs.getInt('upgradeCost') ?? upgradeCost;
      cpuLevel = prefs.getInt('cpuLevel') ?? cpuLevel;
      passiveClicks = prefs.getInt('passiveClicks') ?? passiveClicks;
      doubleClickPowerCost = prefs.getInt('doubleClickPowerCost') ?? doubleClickPowerCost;
      clicksPerBonus = prefs.getInt('clicksPerBonus') ?? clicksPerBonus;
      lessClicksPerBonusCost = prefs.getInt('lessClicksPerBonusCost') ?? lessClicksPerBonusCost;
      multiplierCost = prefs.getInt('multiplierCost') ?? multiplierCost;
      currentDivisionCost = prefs.getInt('currentDivisionCost') ?? currentDivisionCost;
      currentDivision = prefs.getString('currentDivision') ?? currentDivision;
      currentLogo = prefs.getString('currentLogo') ?? currentLogo;
      multiplierCost = prefs.getInt('multiplierCost') ?? multiplierCost;
      // Retrieve and set other variables here
    });
  }

  // Passive upgrade function
  void buyPassiveClick() {
    if (points >= passiveClickCost) {
      setState(() {
        points -= passiveClickCost;
        passiveClicks += 1;
        passiveClickCost += (0.6 * passiveClickCost).round();
        gpuLevel = (gpuLevel + 1) % gpuList.length;
        saveGameState();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content: Text(
                "You need $passiveClickCost points to buy passive clicks."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  // Double click handle
  void handleDoubleClickPowerClick() {
    if (points >= doubleClickPowerCost && !doubleClickPowerActive) {
      setState(() {
        points -= doubleClickPowerCost;
        doubleClickPowerCost = (2.4 * doubleClickPowerCost).round();
        activateDoubleClickPower();
        saveGameState();
      });
    } else if (doubleClickPowerActive) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Double Click Power is already active"),
            content: Text("You can activate it again when it stops."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content: Text(
                "You need $doubleClickPowerCost points to activate Double Click Power."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void activateDoubleClickPower() {
    setState(() {
      doubleClickPowerActive = true;
    });

    doubleClickPowerTimer = Timer(Duration(seconds: 30), () {
      setState(() {
        doubleClickPowerActive = false;
      });
    });
  }

  void showComboSnackbar(int bonusPoints) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Combo Bonus! You've achieved a combo streak! Bonus Points: $bonusPoints"),
        duration: Duration(seconds: 1), // Pop up duration
      ),
    );
  }

  void showComboDialog(int bonusPoints) {
    showComboSnackbar(bonusPoints);
  }

  void levelUpDivision() {
    if (currentDivision == 'High end') {
      saveGameState();
      // Max division reached, disable button and change text
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Max Division Reached"),
            content: Text("You have reached the High end."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (points >= currentDivisionCost) {
      setState(() {
        points -= currentDivisionCost;
        currentDivisionCost *= divisionMultiplier;
        updateCurrentDivision();
        saveGameState();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content: Text(
                "You need $currentDivisionCost points to level up to the next division."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void resetAll() {
    // points = 0;
    clickValue = 1;
    cpuLevel = 0;
    gpuLevel = 0;
    passiveClicks = 0;
    comboCount = 0;
    comboMultiplier = 1;
    clicksPerBonus = 20;
  }

  void updateCurrentDivision() {
    if (currentDivisionCost <= 30000) {
      currentDivision = 'Hobby builder';
      resetAll();
      upgradeCost = 150;
      passiveClickCost = 550;
      doubleClickPowerCost = 550;
      lessClicksPerBonusCost = 550;
      multiplierCost = 550;
      cpuLevel = (cpuLevel + 2) % cpuList.length;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +10 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 10;
      saveGameState();
    } else if (currentDivisionCost <= 90000) {
      currentDivision = 'Casual crafter';
      resetAll();
      upgradeCost = 200;
      passiveClickCost = 600;
      doubleClickPowerCost = 600;
      lessClicksPerBonusCost = 600;
      multiplierCost = 600;
      cpuLevel = (cpuLevel + 2) % cpuList.length;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +30 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 30;
      saveGameState();
    } else if (currentDivisionCost <= 270000) {
      currentDivision = 'Gamer';
      resetAll();
      upgradeCost = 250;
      passiveClickCost = 650;
      doubleClickPowerCost = 650;
      lessClicksPerBonusCost = 650;
      multiplierCost = 650;
      cpuLevel = (cpuLevel + 3) % cpuList.length;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +60 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 60;
      saveGameState();
    } else if (currentDivisionCost <= 810000) {
      currentDivision = 'Professional';
      resetAll();
      upgradeCost = 300;
      passiveClickCost = 700;
      doubleClickPowerCost = 700;
      lessClicksPerBonusCost = 700;
      multiplierCost = 700;
      cpuLevel = (cpuLevel + 3) % cpuList.length;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +100 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 100;
      saveGameState();
    } else if (currentDivisionCost <= 2430000) {
      currentDivision = 'Master';
      resetAll();
      upgradeCost = 350;
      passiveClickCost = 750;
      doubleClickPowerCost = 750;
      lessClicksPerBonusCost = 750;
      multiplierCost = 750;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +150 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 150;
      saveGameState();
    } else if (currentDivisionCost <= 7290000) {
      currentDivision = 'Elite';
      resetAll();
      upgradeCost = 400;
      passiveClickCost = 800;
      doubleClickPowerCost = 800;
      lessClicksPerBonusCost = 800;
      multiplierCost = 800;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to $currentDivision and have +250 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 250;
      saveGameState();
    } else {
      currentDivision = 'High end';
      resetAll();
      upgradeCost = 500;
      passiveClickCost = 1000;
      doubleClickPowerCost = 1000;
      lessClicksPerBonusCost = 1000;
      multiplierCost = 1000;
      // currentLogo = "";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Congrats!"),
            content: Text(
                "You got promoted to max division: $currentDivision and have +500 bonus click points"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      clickValue += 500;
      saveGameState();
    }
  }

  // More multiplier cap bonus
  void buyMultiplier() {
    if (points >= multiplierCost) {
      setState(() {
        points -= multiplierCost;
        multiplierCost += (1.2 * multiplierCost).round();
        maxBonusMultiplier += 5;
        saveGameState();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content:
                Text("You need $multiplierCost points to buy the upgrade."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  // Less clicks needed for bonus points
  void buyLessClicksForBonus() {
    if (clicksPerBonus == 5) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Max Upgrade Reached"),
            content: Text("You have reached 5 clicks for bonus!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (points >= lessClicksPerBonusCost) {
      setState(() {
        points -= lessClicksPerBonusCost;
        lessClicksPerBonusCost += (1.2 * lessClicksPerBonusCost).round();
        clicksPerBonus--;
        saveGameState();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Not enough points"),
            content: Text(
                "You need $lessClicksPerBonusCost points to buy the upgrade."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void infoPopUp() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Upgrade information"),
            content: Column(
              children: [
                Divider(
                  color: Colors.black,
                  thickness: 1.0,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/CPU.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                          width: 10,
                      ),
                      Text("+1 points per click."),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/GPU.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                          width:
                              10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "+1 passive click.",
                          ),
                          Text(
                            "(Every 3 seconds)",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/+5.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("+5 click bonus cap."),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/click.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                          width:
                              10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "-1 click needed for bonus.",
                          ),
                          Text(
                            "(Max 5 clicks)",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/2x.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                          width:
                              10),        
                          Text(
                            "2x clicks for 30 seconds.",
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/levelUp.png',
                        height: 40,
                        width: 40,
                      ),
                      SizedBox(
                          width:
                              10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Upgrades the division",
                          ),
                          Text(
                            "(Resets points and upgrades)",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Center(
            child: Text('PC Builder clicker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ))),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: infoPopUp,
                child: Icon(
                  Icons.info,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: GestureDetector(
                onTap: handleDoubleClickPowerClick,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/2x.png',
                      height: 80,
                      width: 80,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Cost: $doubleClickPowerCost',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: currentDivision == 'High end' ? null : levelUpDivision,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/levelUp.png', height: 80, width: 80),
                    SizedBox(height: 8.0),
                    Text(
                      currentDivision == 'High end'
                          ? 'Maxed'
                          : 'Cost: $currentDivisionCost',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Current division: $currentDivision',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'CPU: ${cpuList[cpuLevel]}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'GPU: ${gpuList[gpuLevel]}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              // Centered elements
              Align(
                alignment: Alignment.center,
                child: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        key: _key,
                        onTap: handleClick,
                        child: Container(
                          width: 200,
                          height: 200,
                          margin: EdgeInsets.only(top: 55, bottom: 20),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('$currentLogo'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '+$clickValue',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Points: $points',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: buyUpgrade,
                  child: Container(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/CPU.png',
                          height: 80,
                          width: 80,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Cost: $upgradeCost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: buyPassiveClick,
                  child: Container(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/GPU.png',
                          height: 80,
                          width: 80,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Cost: $passiveClickCost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: buyMultiplier,
                  child: Container(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/+5.png',
                          height: 80,
                          width: 80,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Cost: $multiplierCost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: clicksPerBonus == 5 ? null : buyLessClicksForBonus,
                  child: Container(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/click.png',
                          height: 80,
                          width: 80,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          clicksPerBonus == 5
                              ? 'Maxed'
                              : 'Cost: $lessClicksPerBonusCost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
