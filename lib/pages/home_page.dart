import 'package:aadatein/components/my_drawer.dart';
import 'package:aadatein/components/my_habit_tile.dart';
import 'package:aadatein/components/my_heat_map.dart';
import 'package:aadatein/database/habit_database.dart';
import 'package:aadatein/models/habit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../util/habit_util.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
    super.initState();
  }

  final TextEditingController textController = TextEditingController();

  void createNewHabit(){
    showDialog(context: context, builder: (context)=> AlertDialog(
        content: TextField(
          controller: textController  ,
          decoration: const InputDecoration(
            hintText: "Create a new habit",
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: (){
              String newHabitName=textController.text;
              context.read<HabitDatabase>().addHabit(newHabitName);
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Save'),
            ),
          MaterialButton(
            onPressed: (){
               Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Cancel'),
            ),
        ],
    ),);
  }

  void checkHabitOnOff(bool? value, Habit habit){
    //update habit completion status
    if(value!=null){
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

   //edit habit box
   void editHabitBox(Habit habit){
    //set the controller's text to habit's current name
    textController.text=habit.name;

    showDialog(context: context, builder: (context) => AlertDialog(
      content: TextField(
        controller: textController,
      ),
      actions: [
        MaterialButton(
            onPressed: (){
              String newHabitName=textController.text;
              context.read<HabitDatabase>().updateHabitName(habit.id, newHabitName);
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Save'),
            ),
          MaterialButton(
            onPressed: (){
               Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Cancel'),
            ),
      ],
    ),
    );
   }

   //delete habit box
   void deleteHabitBox(Habit habit){
    
    showDialog(context: context, builder: (context) => AlertDialog(
      title:const Text('Are you sure you want to delete?'),
      actions: [
        //delete button
        MaterialButton(
            onPressed: (){
              context.read<HabitDatabase>().deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
            ),
            //cancel button
          MaterialButton(
            onPressed: (){
               Navigator.pop(context);
            },
            child: const Text('Cancel'),
            ),
      ],
    ),
    );
   }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
     backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer:const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(Icons.add),
        ),
        body:ListView(
          children: [
            //heatmap
            _buildHeatMap(),
            //habitlist
             _buildHabitList(),
          ],
        ),
    );
  }

  Widget _buildHeatMap(){
    //habit database
  final habitDatabase=context.watch<HabitDatabase>();

    //current habits
    List<Habit> currentHabits= habitDatabase.currentHabits;

    //return heat map ui
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        return MyHeatMap(startDate: snapshot.data!, datasets: prepHeatMapDataset(currentHabits));
      },
    );
  }

  Widget _buildHabitList() {
    final habitDatabase= context.watch<HabitDatabase>();
    List<Habit> currentHabits=habitDatabase.currentHabits;
    return ListView.builder(
      itemCount: currentHabits.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context,index){
      //get each individual habit
      final habit=currentHabits[index];

      //check if it is completed
      bool isCompletedToday = isHabitCompletedToday(habit.completedDays);

      //return habit title ui
      return MyHabitTile(isCompleted: isCompletedToday, text: habit.name,
      onChanged: (value) => checkHabitOnOff(value, habit),
      editHabit: (context) => editHabitBox(habit),
      deleteHabit: (context) => deleteHabitBox(habit),
      );
    });
  }
}