import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClickerGame(),
      theme: new ThemeData(scaffoldBackgroundColor: Color.fromARGB(255, 46, 76, 197)),
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
  int nextUpgrade = 0; // Next upgrade cost
  int upgradesBought = 0;
  List<String> cpuList = [
    'I3-2120', 'i3-3150', 'i3-4010', 'i5-5040', // Need more CPUs
  ];
  int cpuLevel = 0; // index of the current CPU in the list

  // Passive points upgrade
  int passiveClicks = 0;
  int passiveClickCost = 500;
  List<String> gpuList = [
    'RTX4050', 'RTX2050', 'RTX1050', 'RTX1060', 
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
  String currentDivision = 'Bronze';

  String currentLogo = "images/home.webp";

  void showPointsPopup(int earnedPoints) {
    OverlayEntry overlayEntry;

    // Find the position of the tapped widget
    RenderBox renderBox = _key.currentContext?.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);

    // Generate a random offset within the screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double randomX = Random().nextInt(screenWidth.toInt()).toDouble();
    double randomY = Random().nextInt(screenHeight.toInt()).toDouble();

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

    Overlay.of(context)?.insert(overlayEntry);

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
      } else {
        points += clickValue;
        showPointsPopup(1);
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

  // Dispose the timer when the widget is disposed
  @override
  void dispose() {
    comboTimer?.cancel();
    super.dispose();
  }

  // Tap upgrade function
  void buyUpgrade() {
    if (points >= upgradeCost) {
      setState(() {
        points -= upgradeCost;
        clickValue += 1;
        nextUpgrade = (0.5 * upgradeCost).round();
        upgradeCost += nextUpgrade;
        upgradesBought += 1;

        // Increases the CPU when upgrade is bought
        cpuLevel = (cpuLevel + 1) % cpuList.length;
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

  // Passive upgrade function
  void buyPassiveClick() {
    if (points >= passiveClickCost) {
      setState(() {
        points -= passiveClickCost;
        passiveClicks += 1;
        passiveClickCost += (0.6 * passiveClickCost).round();
        gpuLevel = (gpuLevel + 1) % gpuList.length;
      });
      // Timer for passive clicks
      Timer.periodic(Duration(seconds: 3), (timer) {
        setState(() {
          points += passiveClicks;
        });
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
    if (currentDivision == 'Challenger') {
      // Challenger reached, disable button and change text
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Max Division Reached"),
            content: Text("You have reached the maximum division: Challenger."),
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

  void updateCurrentDivision() {
    if (currentDivisionCost <= 30000) {
      currentDivision = 'Silver';
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
    } else if (currentDivisionCost <= 90000) {
      currentDivision = 'Gold';
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
    } else if (currentDivisionCost <= 270000) {
      currentDivision = 'Platinum';
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
    } else if (currentDivisionCost <= 810000) {
      currentDivision = 'Diamond';
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
    } else if (currentDivisionCost <= 2430000) {
      currentDivision = 'Master';
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
    } else if (currentDivisionCost <= 7290000) {
      currentDivision = 'Grandmaster';
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
    } else {
      currentDivision = 'Challenger';
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
    }
  }

  // More multiplier cap bonus
  void buyMultiplier() {
    if (points >= multiplierCost) {
      setState(() {
        points -= multiplierCost;
        multiplierCost += (1.2 * multiplierCost).round();
        maxBonusMultiplier += 5;
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

  // Less needed clicks for bonus points
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Center(child: Text('Clicker Game')),
      ),
      body:Stack(
      children: [
        // Background Image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background2.png'),
              fit: BoxFit.cover,
            ),
          ),
        ), Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Current division: $currentDivision',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Text('CPU: ${cpuList[cpuLevel]}', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Text('GPU: ${gpuList[gpuLevel]}', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),

          // Centered elements
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  key: _key,
                  onTap: handleClick,
                  child: Container( 
                    width: 250,
                    height: 250,
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('$currentLogo'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$clickValue',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Text('Points: $points', style: TextStyle(fontSize: 18, color: Colors.white)),
                ElevatedButton(
                  onPressed: buyUpgrade,
                  child: Text('Buy Upgrade (Cost: $upgradeCost points)'),
                ),
                ElevatedButton(
                  onPressed: buyPassiveClick,
                  child: Text(
                      'Buy Passive Click (Cost: $passiveClickCost points)'),
                ),
                ElevatedButton(
                  onPressed: handleDoubleClickPowerClick,
                  child: Text(doubleClickPowerActive
                      ? 'Double Click Power Active'
                      : 'Activate Double Click Power (Cost: $doubleClickPowerCost points)'),
                ),
                ElevatedButton(
                  onPressed:
                      currentDivision == 'Challenger' ? null : levelUpDivision,
                  child: Text(
                    currentDivision == 'Challenger'
                        ? 'Max Division Reached'
                        : 'Level Up Division (Cost: $currentDivisionCost points)',
                  ),
                ),
                ElevatedButton(
                  onPressed: buyMultiplier,
                  child: Text(
                      'Buy More Multiplier (Cost: $multiplierCost points)'),
                ),
                ElevatedButton(
                  onPressed:
                      clicksPerBonus == 5 ? null : buyLessClicksForBonus,
                  child: Text(
                    clicksPerBonus == 5
                      ? 'Max multiplier reached'
                      : 'Buy Less Clicks per bonus (Cost: $lessClicksPerBonusCost points)'),
                ),
              ],
            ),
          ),
        ],
      ),
  ],),);
  }
}
