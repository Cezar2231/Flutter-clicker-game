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
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClickerGame extends StatefulWidget {
  @override
  _ClickerGameState createState() => _ClickerGameState();
}

class _ClickerGameState extends State<ClickerGame> {
  int points = 0; //points
  GlobalKey _key = GlobalKey();

  //Tap upgrade
  int clickValue = 1000000; //starting click points
  int upgradeCost = 100; //first tap upgrade cost
  int nextUpgrade = 0; //next upgrade cost
  int upgradesBought = 0; //amount of upgrades bought

  //Passive upgrade
  int passiveClicks = 0; // passive click
  int passiveClickCost = 500; //first passive click cost

  //Double tap powerup
  bool doubleClickPowerActive = false;
  int doubleClickPowerCost = 500;
  Timer? doubleClickPowerTimer;

  //Combo multiplier
  int comboCount = 0;
  int comboMultiplier = 1;
  int clicksPerBonus = 20;
  int maxBonusMultiplier = 5;
  Timer? comboTimer;

  //Divisions
  int currentDivisionCost = 10000;
  int divisionMultiplier = 3;
  String currentDivision = 'Bronze';

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
                  color: Colors.black, // Customize the text color
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

      //combo streak
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

        //restart the combo timer
        restartComboTimer();
      }
    });
  }

  void restartComboTimer() {
    //cancel the existing timer
    comboTimer?.cancel();

    //starts a new timer to reset combo after 5 seconds of inactivity
    comboTimer = Timer(Duration(seconds: 5), () {
      setState(() {
        comboCount = 0;
        comboMultiplier = 1;
      });
    });
  }

  //dispose the timer when the widget is disposed
  @override
  void dispose() {
    comboTimer?.cancel();
    super.dispose();
  }

  void buyUpgrade() {
    if (points >= upgradeCost) {
      setState(() {
        points -= upgradeCost;
        clickValue += 1;
        nextUpgrade = (0.5 * upgradeCost).round();
        upgradeCost += nextUpgrade;
        upgradesBought += 1;
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

  void buyPassiveClick() {
    if (points >= passiveClickCost) {
      setState(() {
        points -= passiveClickCost;
        passiveClicks += 1;
        passiveClickCost += (0.6 * passiveClickCost).round();
      });
      // Start a timer for passive clicks
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
        duration: Duration(seconds: 1), //pop up duration
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
    } else if (currentDivisionCost <= 90000) {
      currentDivision = 'Gold';
    } else if (currentDivisionCost <= 270000) {
      currentDivision = 'Platinum';
    } else if (currentDivisionCost <= 810000) {
      currentDivision = 'Diamond';
    } else if (currentDivisionCost <= 2430000) {
      currentDivision = 'Master';
    } else if (currentDivisionCost <= 7290000) {
      currentDivision = 'Grandmaster';
    } else {
      currentDivision = 'Challenger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Center(child: Text('Clicker Game')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              key: _key,
              onTap: handleClick,
              child: Container(
                width: 100,
                height: 100,
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$clickValue',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Text('Points: $points', style: TextStyle(fontSize: 18)),
            Text(
              '+$currentDivision',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: buyUpgrade,
              child: Text('Buy Upgrade (Cost: $upgradeCost points)'),
            ),
            ElevatedButton(
              onPressed: buyPassiveClick,
              child: Text('Buy Passive Click (Cost: $passiveClickCost points)'),
            ),
            ElevatedButton(
              onPressed: handleDoubleClickPowerClick,
              child: Text(doubleClickPowerActive
                  ? 'Double Click Power Active'
                  : 'Activate Double Click Power (Cost: $doubleClickPowerCost points'),
            ),
            ElevatedButton(
              onPressed:
                  currentDivision == 'Challenger' ? null : levelUpDivision,
              child: Text(
                currentDivision == 'Challenger'
                    ? 'Max Division Reached'
                    : 'Level Up Division (Cost: $currentDivisionCost points)',
              ),
            )
          ],
        ),
      ),
    );
  }
}
