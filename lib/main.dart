import 'dart:io';

import 'package:blags/Model/BlogModel.dart';
import 'package:blags/shared_preference/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<Blog> blogs = [];
  bool net = false;
  Future<void> isInternetAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
    } else {
      fetchData();
      net = true;
    }
  }

  @override
  initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    isInternetAvailable();
  }

  Future<void> fetchData() async {
    // Fetch and save blogs, retrieve blogs from SharedPreferences
    await BlogHelper.fetchAndSaveBlogs();
    List<Blog>? storedBlogs = await BlogHelper.getBlogsFromLocalStorage();
    if (storedBlogs != null) {
      setState(() {
        blogs = storedBlogs;
      });
    }
  }

  late TabController _tabController;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 83, 81, 81),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Blog and Articles',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          labelColor: Colors.white,
          isScrollable: true,
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              text: 'Blog',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          blogs.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ), // Show loading indicator
                )
              : ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Container(
                            height: size.height * 0.28,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(
                                        File(blogs[index].imageUrl!))),
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          Container(
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.all(10),
                            child: Text(
                              blogs[index].title!,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    );
                  })
        ],
      ),
    );
  }

  String getCategoryName(int index) {
    // Replace with your category names or use dynamic category names
    switch (index) {
      case 0:
        return 'All';
      case 1:
        return 'Business';
      case 2:
        return 'Tutorial';
      case 3:
        return 'Sports';
      default:
        return 'Category $index';
    }
  }
}
