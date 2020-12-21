import 'package:flutter/material.dart';
import 'package:food_app/classes/FavouriteStorage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../classes/Recipe.dart';

class FavoriteListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lime,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FavoriteList(storage: FavouriteStorage()),
    );
  }
}

class FavoriteList extends StatefulWidget {
  final FavouriteStorage storage;
  FavoriteList({Key key, @required this.storage}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FavoriteListState();
  }
}

class FavoriteListState extends State<FavoriteList> {
  var favourites = [];
  List<String> favouritesString = [];
  String loadString;

  @override
  void initState() {
    super.initState();
    widget.storage
        .readFavourites()
        .then((value) => {favouritesFinished(value), stringToList()});
  }

  List<String> favouritesFinished(List<String> fav) {
    setState(() {
      favouritesString = fav;
      print("Asynchrones Laden von der Datei:" + favouritesString.toString());
    });
    return fav;
  }

  stringToList() {
    print('call StringToList');
    print(favouritesString.toString());
    for (String favourite in favouritesString) {
      print("Before error");
      List<String> singleComponentsRecipe = favourite.split("_SEPERATOR_");
      print(singleComponentsRecipe.toString());
      if (singleComponentsRecipe.length == 4) {
        Recipe currentFav = Recipe(
            title: singleComponentsRecipe[0],
            href: singleComponentsRecipe[1],
            ingredients: singleComponentsRecipe[2],
            thumbnail: singleComponentsRecipe[3]);
        print("current Recipe:" + currentFav.toString());
        favourites.add(currentFav);
      }
      print("After adding recipes:" + favourites.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: _printFavorites(),
          ),
        ),
      ),
    );
  }

  List<Widget> _printFavorites() {
    List<Widget> printedFavorites = new List();
    int i;
    print("Before for Loop:" + favourites.toString());
    for (i = 0; i < favourites.length; i++) {
      Recipe current = favourites[i];
      bool isSaved = favourites.contains(favourites[i]);
      printedFavorites.add(Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Image.network(favourites[i].thumbnail),
                trailing: IconButton(
                  icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                  color: isSaved ? Colors.red : null,
                  onPressed: () {
                    setState(() {
                      if (isSaved) {
                        print("Before removing favourite:" +
                            favourites.toString());
                        print(i);
                        favourites.remove(current);
                        print("After removing favourite:" +
                            favourites.toString());
                      } else {
                        print(
                            "Before adding favourite:" + favourites.toString());
                        print(i);
                        favourites.add(current);
                        print(
                            "After adding favourite:" + favourites.toString());
                      }
                      _saveFavourites();
                    });
                  },
                ),
                title: Text(favourites[i].title),
                subtitle: Text("Ingredients: " + favourites[i].ingredients),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    child: const Text('CHECK IT OUT'),
                    onPressed: () {
                      _launchURL(favourites[i].href);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ));
      printedFavorites.add(SizedBox(
        height: 10,
      ));
    }

    if (printedFavorites.length == 0) {
      printedFavorites.add(Text("No favorites selected"));
    }

    return printedFavorites;
  }

  _saveFavourites() {
    String currentfavourites = "";
    for (Recipe current in favourites) {
      if (current != null) currentfavourites = currentfavourites + current.toString() + ";";
    }
    print("Before saving" + currentfavourites);
    widget.storage.writeFavourite(currentfavourites);
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
