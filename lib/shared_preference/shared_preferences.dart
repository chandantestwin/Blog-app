import 'dart:convert';
import 'dart:io';

import 'package:blags/Model/BlogModel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BlogHelper {
  static const String blogsKey = 'blogs';
  static const String localImagesDirectory = 'blog_images';

  static Future<void> saveBlogsToLocalStorage(List<Blog> blogs) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> blogStringList =
        blogs.map((blog) => json.encode(blog.toJson())).toList();
    await prefs.setStringList(blogsKey, blogStringList);
  }

  static Future<List<Blog>?> getBlogsFromLocalStorage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? blogStringList = prefs.getStringList(blogsKey);

    if (blogStringList == null) {
      return null;
    }

    final List<Blog> blogs = blogStringList.map((blogString) {
      final Map<String, dynamic> blogMap = json.decode(blogString);
      return Blog.fromJson(blogMap);
    }).toList();

    return blogs;
  }

  static Future<String> getImagePath(String imageUrl) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String localImagePath =
        '$appDocPath/$localImagesDirectory/${_getImageNameFromUrl(imageUrl)}';
    File localImage = File(localImagePath);
    if (await localImage.exists()) {
      return localImagePath;
    } else {
      return _saveImageLocally(imageUrl, localImagePath);
    }
  }

  static String _getImageNameFromUrl(String imageUrl) {
    final Uri uri = Uri.parse(imageUrl);
    return '${uri.pathSegments.last}';
  }

  static Future<String> _saveImageLocally(
      String imageUrl, String localImagePath) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String localDirectoryPath = '$appDocPath/$localImagesDirectory';

    // Create a directory if it doesn't exist
    Directory(localDirectoryPath).createSync(recursive: true);

    // Download the image and save it locally
    HttpClient httpClient = HttpClient();
    File file = File(localImagePath);
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(imageUrl));
    HttpClientResponse response = await request.close();
    await response.pipe(file.openWrite());

    return localImagePath;
  }

  static Future<void> fetchAndSaveBlogs() async {
    final String url = 'https://intent-kit-16.hasura.app/api/rest/blogs';
    final String adminSecret =
        '32qR4KmXOIpsGPQKMqEJHGJS27G5s7HdSKO3gdtQd2kv5e852SiYwWNfxkZOBuQ6';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'x-hasura-admin-secret': adminSecret,
      });

      print(response);
      if (response.statusCode == 200) {
        print(response.body);
        final responseData = json.decode(response.body);
        List<Blog> blogs = [];

        for (int i = 0; i < 50; i++) {
          final Blog blog = Blog.fromJson(responseData["blogs"][i]);
          blog.imageUrl =
              await getImagePath(blog.imageUrl!); // Save image locally
          blogs.add(blog);
        }

        await saveBlogsToLocalStorage(blogs); // Save blogs to SharedPreferences
      } else {
        print('Request failed with status code: ${response.statusCode}');
        print('Response data: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
