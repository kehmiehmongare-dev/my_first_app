import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String userApiUrl = 'https://randomuser.me/api/?results=20';

  // GET - Fetch users from API
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(userApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];
        return results
            .map((user) => {
                  'name': '${user['name']['first']} ${user['name']['last']}',
                  'email': user['email'],
                  'phone': user['phone'],
                  'country': user['location']['country'],
                  'picture': user['picture']['medium'],
                })
            .toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Fetch posts
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST - Create new post
  static Future<Map<String, dynamic>> createPost(
      Map<String, dynamic> post) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(post),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT - Update post
  static Future<Map<String, dynamic>> updatePost(
      int id, Map<String, dynamic> post) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(post),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update post');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE - Delete post
  static Future<bool> deletePost(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
