import 'package:aadatein/models/app_settings.dart';
import 'package:aadatein/models/habit.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier{
  static late Isar isar;

  /*
  SETUP
  */
   
  //initialize database
  static Future<void> initialize() async{
    final dir= await getApplicationDocumentsDirectory();
    isar = await Isar.open([HabitSchema, AppSettingsSchema], directory: dir.path);
  }

  //save first day of opening app - to start heatmap
  Future<void> saveFirstLaunchDate() async{
    final existingSettings = await isar.appSettings.where().findFirst();
    if(existingSettings==null){
      final settings = AppSettings()..FirstLaunchDate = DateTime.now();
      await isar.writeTxn(()=> isar.appSettings.put(settings));
    }
  }

  //get first day of opening app - for heatmap
  Future<DateTime?> getFirstLaunchDate() async{
    final settings= await isar.appSettings.where().findFirst();
    return settings?.FirstLaunchDate;
  } 



  //LIST OF CRUD
  
  //list of habits
  final List<Habit> currentHabits = [];

  //create - add a new habit
  Future<void> addHabit(String habitName) async{
    final newHabit = Habit()..name = habitName;
    await isar.writeTxn(() => isar.habits.put(newHabit));
    readHabits(); 
  }
  
  //update - edit a habit name
  Future<void> updateHabitName(int id,String name) async{
    final habit=await isar.habits.get(id);
    if(habit!=null){
      await isar.writeTxn(() async {
          habit.name=name;
          await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  //update - edit a habit daily check
  Future<void> updateHabitCompletion(int id,bool isCompleted) async{
    final habit=await isar.habits.get(id); //find specific habit macha
    if(habit!=null){
      await isar.writeTxn(()async {
        //if habit is completed macha,then u add current date to completed days list
        if(isCompleted && !habit.completedDays.contains(DateTime.now())){
            final today=DateTime.now();
            habit.completedDays.add(DateTime(today.year,today.month,today.day)); 
        }


        else{ //if habit not done, then shame on u and remove current date from list
        
          habit.completedDays.removeWhere(
            (date)=> 
            date.year==DateTime.now().year && 
            date.month==DateTime.now().month && 
            date.day==DateTime.now().day,  );
        }

        await isar.habits.put(habit);
      });
    }
  }
  
  //delete - delete existign habit
  Future<void> deleteHabit(int id) async{
    await isar.writeTxn(()async{
      await isar.habits.delete(id);
    });
    readHabits();
  }

  //read - read habits from db
  Future<void> readHabits() async{
    List<Habit> fetchedHabits= await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    notifyListeners(); //to update ui
  }

}