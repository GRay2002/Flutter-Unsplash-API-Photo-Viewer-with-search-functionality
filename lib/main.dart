import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unsplash Flutter App with search',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.purple[200],
        appBarTheme: AppBarTheme(
          color: Colors.deepPurple[900],
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class Photo {
  Photo({
    required this.id,
    required this.description,
    required this.imageUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      description: json['description'] != null ? json['description'] as String : 'No description',
      imageUrl: json['urls']['regular'] as String,
    );
  }

  final String id;
  final String description;
  final String imageUrl;
}

class UnsplashApi {
  static const String apiKey = 'tACkK8zx_wVYlLaBtAmh86X8AXAgD4tkEkLpmSOr1Xo';
  static const String apiUrl = 'https://api.unsplash.com';
  static const int perPage = 10;

  // Function to search photos using the Unsplash API
  static Future<List<Map<String, dynamic>>> searchPhotos(String query, int page) async {
    final http.Response response = await http.get(
      Uri.parse('$apiUrl/search/photos?query=$query&page=$page&per_page=$perPage'),
      headers: <String, String>{'Authorization': 'Client-ID $apiKey'},
    );

    // Check if the response is OK
    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(data['results'] as List<dynamic>);
      return List<Map<String, dynamic>>.from(results.map((dynamic item) => item as Map<String, dynamic>));
    } else {
      throw Exception('Failed to load photos');
    }
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  // Build the main page, similar to the previous homework( a.k.a. I just copied the code from the previous homework xD )
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unsplash Flutter App with search functionality',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              // Navigate to the search page
              MaterialPageRoute<void>(builder: (BuildContext context) => const SearchPage()),
            );
          },
          child: const Text('Search Photos'),
        ),
      ),
    );
  }
}

// New class to represent the search page
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

// New class to track the state of the search page
class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Photo> _photos = <Photo>[];
  // variables to track the page number and loading state
  int _page = 1;
  bool _loading = false;
  bool _noResults = false; // variable to track if there are no results
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadPhotos(String query) async {
    setState(() {
      _loading = true;
    });

    // Call the Unsplash API and wait for the results
    final List<Map<String, dynamic>> photos = await UnsplashApi.searchPhotos(query, _page);

    setState(() {
      if (_page == 1) {
        _photos.clear();
        _noResults = false; // Reset the noResults flag when starting a new search
      }

      // Add the results to the list
      _photos.addAll(photos.map((Map<String, dynamic> json) => Photo.fromJson(json)));
      _page++;

      // If there are no results, set the noResults flag to true
      if (_photos.isEmpty) {
        _noResults = true;
      }

      // Set the loading flag to false
      _loading = false;
    });
  }

  // Function to listen to the scroll event and load more photos when the user reaches the bottom of the list
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _scrollController.offset > 0) {
      // Load more photos when the user reaches the bottom of the list
      _loadPhotos(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Search bar and button
            TextField(
              // Set the controller to track the search query
              controller: _searchController,
              // Set the keyboard type to text
              decoration: const InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _page = 1;
                _loadPhotos(_searchController.text);
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _photos.isEmpty
                      ? _noResults
                          ? const Center(child: Text('No results found. Try a different search.'))
                          : Container() // Show nothing when the search results are being loaded
                      : _buildPhotoList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoList() {
    return ListView.builder(
      itemCount: _photos.length + 1, // Add 1 for loading indicator
      itemBuilder: (BuildContext context, int index) {
        if (index < _photos.length) {
          final Photo photo = _photos[index];
          // Limit the description to 50 characters
          final String limitedDescription =
              photo.description.length > 50 ? '${photo.description.substring(0, 50)}...' : photo.description;

          return GestureDetector(
            onTap: () {
              _showLargerImage(photo.imageUrl);
            },
            child: SizedBox(
              height: 80,
              child: ListTile(
                title: Text(
                  limitedDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                contentPadding: const EdgeInsets.all(8.0),
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  void _showLargerImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: SizedBox(
            width: 360,
            height: 360,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
