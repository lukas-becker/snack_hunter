//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom;
import 'package:food_app/classes/Favorite.dart';
import 'package:food_app/classes/DatabaseUtil.dart';
import 'package:food_app/classes/Item.dart';
import 'package:http/http.dart' as http;
import 'package:powerset/powerset.dart';
import 'dart:convert';
import 'package:food_app/globalVariables.dart' as globals;

import '../classes/Recipe.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

//Center Tab Recipe List
class RecipeListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lime,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Recipes(
          title: ''));
  }

  //Getter for filtering
  static List<Recipe> getRecipes() {
    return Recipes.getRecipes();
  }
}

class Recipes extends StatefulWidget {
  Recipes({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RecipesState createState() => _RecipesState();

  //Getter for filtering
  static List<Recipe> getRecipes() {
    return _RecipesState.getRecipes();
  }
}

class _RecipesState extends State<Recipes> {
  //Variable to hold Recipes
  List<Widget> displayedRecipes = new List();

  //Recipe Storage
  var futureRecipes = [];
  static List<Recipe> recipes = new List();
  List<Favorite> favorites = new List();
  var favouriteRecipes = [];
    List<Item> ingredients;

  //filtering
  List<String> allIngredients = new List();

  //for Textboxes
  final tController = new TextEditingController();

  //Load json from Api, ingredient as parameter
  Future<List<Recipe>> fetchJson(String ingr) async {
    //Remove [ and ] from String
    ingr = ingr.substring(1, ingr.length - 1);
    //trim
    ingr = ingr.replaceAll(" ", "");
    print('Downloading: http://www.recipepuppy.com/api/?i=' + ingr);
    final response =
        await http.get('http://www.recipepuppy.com/api/?i=' + ingr);
    if (response.statusCode == 200) {
      print("Got response");
      List list = jsonDecode(response.body)['results'];
      //Parse result to Recipes
      List<Recipe> res = List.generate(
          list.length,
          (index) =>
              Recipe.fromJson(jsonDecode(response.body)['results'][index]));


      //To prevent results appearing multiple times
      List<Recipe> toRemove = new List(); //temporary List instead of directly removing, because flutter throws exceptions if you remove elements while iterating over list
      for(Recipe r in res){
        for (Recipe ri in recipes){
          if (r == ri){
            toRemove.add(r);
          }
        }
      }
      for(Recipe r in toRemove){
        res.remove(r);
      }

      return res;
    }
  }

  ///Full text search
  Future<List<Recipe>> _searchRecipeApi(String recipeName) async {
    print("Downloading: http://www.recipepuppy.com/api/?q=" + recipeName);
    List<Recipe> res = [];
    final response =
        await http.get("http://www.recipepuppy.com/api/?q=" + recipeName);
    if (response.statusCode == 200) {
      print("got Response");
      List list = jsonDecode(response.body)['results'];
      //Parse result to Recipes
      res = List.generate(
          list.length,
          (index) =>
              Recipe.fromJson(jsonDecode(response.body)['results'][index]));
    }
    res.forEach((element) {
      print(element.toString());
    });
    return res;
  }

  @override
  void initState() {
    super.initState();
    if (!globals.search) {
      //Ingredients from "Pantry"
      DatabaseUtil.getDatabase();
      DatabaseUtil.getIngredients()
          .then((value) => ingredientsFetchComplete(value));
    } else {
      //Full text search
      _searchRecipeApi(globals.searchString)
          .then((value) => setRecipeList(value));
    }
    //Favorites
    DatabaseUtil.getFavorites().then((value) => favoritesFetchComplete(value));
  }

  ///After Ingredients were fetched from local dB
  void ingredientsFetchComplete(List<Item> ingr) {
    ingr.forEach((element) {
      allIngredients.add(element.name.toUpperCase());
    });
    //Check Api for Ingredient and add result to list
    powerset(ingr).forEach((element) {
      if (element.toString() != "[]") {
        print("Checking api for: " + element.toString());
        fetchJson(element.toString()).then((value) => addToRecipeList(value));
      }
    });
  }

  ///Add Api Results to List
  void addToRecipeList(List<Recipe> newRecipes) {
    newRecipes.forEach((element) {
      recipes.add(element);
    });
    setState(() {
      _RecipesState.recipes = recipes;
    });
  }

  ///After Favorites returned from local DB
  void favoritesFetchComplete(List<Favorite> fav) {
    //Add to list
    fav.forEach((element) {
      favorites.add(element);
    });

    setState(() {
      this.favorites = favorites;
    });
  }

  ///Set list after filter
  void setRecipeList(List<Recipe> searchedRecipes) {
    recipes = [];
    searchedRecipes.forEach((element) {
      recipes.add(element);
    });
    setState(() {
      _RecipesState.recipes = recipes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(children: _compileRecipes()),
        ),
      ),
    );
  }

  List<Widget> result = new List();

  ///Compile list of Recipes to be printed
  List<Widget> _compileRecipes() {
    setState(() {
      result = [];
    });
    //Margin
    result.add(SizedBox(
      width: 8,
      height: 15,
    ));
    //Iterate over each recipe
    for (int i = 0; i < recipes.length; i++) {
      //Replace with default thumbnail
      if (recipes[i].thumbnail == null)
        recipes[i].thumbnail =
            "https://upload.wikimedia.org/wikipedia/commons/e/ea/No_image_preview.png";

      //Exact results filter
      bool _continue = false;
      //If only "makeable" recipes should be shown
      if (globals.exact) {
        //Ingredients of current recipe
        String _ingredients = recipes[i].ingredients;
        //One ingredient of possible list
        String _ingredient;
        //count how many ingredients there are
        int countIngredients = _ingredients.split(",").length;
        /*print("Ingredients for recipe (" +
            countIngredients.toString() +
            "): " +
            _ingredients);*/
        //Loop variables
        int index = 0;
        int nextIndex;
        for (int j = 0; j < countIngredients; j++) {
          nextIndex = _ingredients.indexOf(",", index);

          if (nextIndex == -1) {
            //print("Checking range from " + index.toString());
            _ingredient = _ingredients.substring(index).toUpperCase();
          } else {
            /*print("Checking range between " +
                index.toString() +
                " and " +
                nextIndex.toString());*/
            _ingredient =
                _ingredients.substring(index, nextIndex).toUpperCase();
          }

          if (_ingredient.startsWith(" "))
            _ingredient = _ingredient.replaceFirst(" ", "");

          //print("checking: " + _ingredient);
          if (_ingredient.contains(" ")) {
            int spaceIndex = 0;
            int nextSpaceIndex;
            int loopCondition = _ingredient.split(" ").length;

            //Only for ingredients with a space
            bool multiWordContinueTemp = false;
            for (int k = 0; k < loopCondition; k++) {
              String toCheck;

              nextSpaceIndex = _ingredient.indexOf(" ", spaceIndex);

              //print("spaceIndex: " + spaceIndex.toString());

              if (nextSpaceIndex == -1)
                toCheck = _ingredient.substring(spaceIndex);
              else
                toCheck = _ingredient.substring(
                    spaceIndex, _ingredient.indexOf(" ", spaceIndex));

              if (toCheck.startsWith(" "))
                toCheck = toCheck.replaceFirst(" ", "");

              /*print("Checking: " +
                  toCheck +
                  " (" +
                  (k + 1).toString() +
                  "/" +
                  (loopCondition).toString() +
                  ")");*/
              //Compare
              if (!(allIngredients.contains(toCheck))) {
                multiWordContinueTemp = true;
                //print(toCheck + " is not in the List");
              } else {
                multiWordContinueTemp = false;
                //print(toCheck + " is in the List");
                break;
              }

              spaceIndex = nextSpaceIndex + 1;
            }

            if (multiWordContinueTemp) _continue = true;
          } else {
            //Compare
            if (!(allIngredients.contains(_ingredient.toUpperCase()))) {
              //print(_ingredient + " is not in the List");
              _continue = true;
            }
          }

          index = nextIndex + 1;
        }
      }

      if (_continue) continue;

      bool isSaved = false;
      int favIndex;
      //Check if current recipe is favorite
      favorites.forEach((element) {if(element.recipe == recipes[i]) {isSaved = true; favIndex = favorites.indexOf(element);}} );


      //Margin
      result.add(SizedBox(
        width: 8,
        height: 15,
      ));
      //Display Card
      result.add(Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {
            //print('Card tapped.');
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                  leading: Image.network(recipes[i].thumbnail),
                  trailing: IconButton(
                    color: isSaved ? Colors.red : null,
                    onPressed: () {
                      //Add or remove Favorite
                      if (isSaved) {
                        DatabaseUtil.deleteFavorite(favorites[favIndex]); //.then((value) => setState((){favorites.remove(favIndex);}));
                        favorites.removeAt(favIndex);
                        setState(() {
                          this.favorites = favorites;
                        });
                      } else {
                        DatabaseUtil.getNextFavoriteID().then((value) => {
                          setState(() {
                            favorites.add(Favorite(id: value, recipe: recipes[i]));
                          }),
                          DatabaseUtil.insertFavorite(Favorite(id: value, recipe: recipes[i]))
                        });
                      }
                    },
                    icon:
                    Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                  ),
                  title: Text(recipes[i].title),
                  subtitle: Text("Ingredients: " + recipes[i].ingredients)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    //Show recipe in custom tab
                    child: const Text('CHECK IT OUT'),
                    onPressed: () {
                      _launchURL(context, recipes[i].href);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    //Display message if no recipes match criteria
    if (recipes.length == 0) {
      result.add(SizedBox(
        width: 8,
        height: 15,
      ));
      result.add(Text("You have nothing in your Pantry!"));
      result.add(Text("Add some food, to see what you could cook!"));
      result.add(RaisedButton(
          color: Colors.green,
          onPressed: () {
            TabController tc = DefaultTabController.of(context);
            tc.animateTo(tc.index - 1);
          },
          child: Text("Take me there")));
    }
    //Display message if no results  match criteria
    if (result.length == 0) {
      result.add(SizedBox(
        width: 8,
        height: 15,
      ));
      result.add(Text("Your Filter fit no results!"));
      result.add(Text("Add some food, or adjust it!"));
      result.add(RaisedButton(
          color: Colors.green,
          onPressed: () {
            TabController tc = DefaultTabController.of(context);
            tc.animateTo(tc.index - 1);
          },
          child: Text("Take me to the Pantry")));
    }


    return result;
  }
  ///Launch url in Chrome Custom Tab
  _launchURL(BuildContext context, String url) async {
    try {
      await custom.launch(
        url,
        option: new custom.CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            animation: new custom.CustomTabsAnimation.slideIn()),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      debugPrint(e.toString());
    }
  }
  ///Getter
  static List<Recipe> getRecipes() {
    return recipes;
  }
}
