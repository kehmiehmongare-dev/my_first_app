import 'dart:convert';
import 'package:http/http.dart' as http;

class JsonApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  // ==================== JSONPLACEHOLDER API ====================

  // GET - Fetch posts
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/posts'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      throw Exception('Failed to load posts: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Fetch single post
  static Future<Map<String, dynamic>> fetchPost(int id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/posts/$id'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST - Create new post
  static Future<Map<String, dynamic>> createPost(
      Map<String, dynamic> post) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(post),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT - Update post
  static Future<Map<String, dynamic>> updatePost(
      int id, Map<String, dynamic> post) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/posts/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(post),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to update post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE - Delete post
  static Future<bool> deletePost(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/posts/$id'));
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== RANDOMUSER API ====================

  // GET - Fetch random users
  static Future<List<Map<String, dynamic>>> fetchRandomUsers(
      {int count = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('https://randomuser.me/api/?results=$count'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((user) {
          return {
            'name': '${user['name']['first']} ${user['name']['last']}',
            'firstName': user['name']['first'],
            'lastName': user['name']['last'],
            'email': user['email'],
            'phone': user['phone'],
            'country': user['location']['country'],
            'city': user['location']['city'],
            'picture': user['picture']['large'],
            'thumbnail': user['picture']['thumbnail'],
            'gender': user['gender'],
            'dob': user['dob']['date'],
          };
        }).toList();
      }
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== CUSTOM API (Example) ====================

  // GET - Fetch from custom API
  static Future<Map<String, dynamic>> fetchCustomApi(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST - Send to custom API
  static Future<Map<String, dynamic>> postToCustomApi(
      String url, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
