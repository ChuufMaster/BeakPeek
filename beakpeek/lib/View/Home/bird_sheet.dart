// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'dart:convert';
import 'package:beakpeek/Model/bird.dart';
import 'package:beakpeek/View/Home/heat_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class BirdSheet extends StatefulWidget {
  const BirdSheet({super.key, required this.pentadId});
  final String pentadId;

  @override
  _BirdSheetState createState() => _BirdSheetState();
}

class _BirdSheetState extends State<BirdSheet> {
  double _heightFactor = 0.5; // Initial height factor
  String _selectedSortOption = 'Sort';
  String _selectedFilterOption = 'All';
  late Future<List<Bird>> _birdList;

  @override
  void initState() {
    super.initState();
    _birdList = fetchBirds(widget.pentadId,
        http.Client()); // Fetch and sort birds from the API initially
  }

  void _refreshBirdList() {
    _birdList = fetchBirds(widget.pentadId, http.Client()).then((birds) {
      // Sort the list of birds based on the selected sort option
      return _sortBirds(birds, _selectedSortOption);
    }).catchError((error) {
      // Handle error fetching birds
      print('Error fetching birds: $error');
      throw Exception('Failed to load birds: $error');
    });
  }

  List<Bird> _sortBirds(List<Bird> birds, String sortOption) {
    // Sorting logic based on the selected sort option
    switch (sortOption) {
      case 'Rarity Asc':
        birds.sort((a, b) => a.reportingRate.compareTo(b.reportingRate));
        break;
      case 'Rarity Desc':
        birds.sort((a, b) => b.reportingRate.compareTo(a.reportingRate));
        break;
      case 'Alphabetically Asc':
        birds.sort((a, b) => a.commonGroup.compareTo(b.commonGroup));
        break;
      case 'Alphabetically Desc':
        birds.sort((a, b) => b.commonGroup.compareTo(a.commonGroup));
        break;
      default:
        // No sorting
        break;
    }
    return birds;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _heightFactor -=
              details.primaryDelta! / MediaQuery.of(context).size.height;
          _heightFactor = _heightFactor.clamp(
              0.2, 0.9); // Limit height factor between 0.2 and 1.0
        });
      },
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: _heightFactor,
        child: Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 24.0,
                child: Center(
                  child: Container(
                    height: 4.0,
                    width: 48.0,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Birds in this area',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: DropdownButton<String>(
                      value: _selectedSortOption,
                      items: <String>[
                        'Sort',
                        'Rarity Asc',
                        'Rarity Desc',
                        'Alphabetically Asc',
                        'Alphabetically Desc'
                      ].map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSortOption = newValue!;
                          _refreshBirdList();
                        });
                      },
                    ),
                  ),
                  Flexible(
                    child: DropdownButton<String>(
                      value: _selectedFilterOption,
                      items: <String>[
                        'Birds You\'ve Seen',
                        'Birds You Haven\'t Seen',
                        'All'
                      ].map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedFilterOption = newValue!;
                          _refreshBirdList();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<Bird>>(
                  future: _birdList,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('No birds found.'));
                    }
                    return BirdList(birds: snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List<Bird>> fetchBirds(String pentadId, http.Client client) async {
  try {
    // print(pentadId);
    final response = await client.get(Uri.parse(
        'http://10.0.2.2:5000/api/Bird/$pentadId/pentad'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Bird.fromJson(data)).toList();
    } else {
      print('Request failed with status: ${response.statusCode}');
      throw Exception('Failed to load birds');
    }
  } catch (error) {
    print('Error fetching birds BRUH: $error');
    throw Exception(error);
  }
}

class BirdList extends StatelessWidget {
  const BirdList({super.key, required this.birds});
  final List<Bird> birds;

  @override
  Widget build(BuildContext context) {
  return Material(
    child: ListView.builder(
      itemCount: birds.length,
      itemBuilder: (context, index) {
        final bird = birds[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: HeatMap(
                    commonGroup: bird.commonGroup,
                    commonSpecies: bird.commonSpecies,
                  ),
                ),
              ),
            );
          },
          child: ListTile(
            title: Text(bird.commonGroup != 'None'
                ? '${bird.commonGroup} ${bird.commonSpecies}'
                : bird.commonSpecies),
            subtitle: Text('Scientific Name: ${bird.genus} ${bird.species}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${bird.reportingRate}%'),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorForReportingRate(bird.reportingRate),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Color _getColorForReportingRate(double reportingRate) {
    if (reportingRate < 40) {
      return Colors.red;
    } else if (reportingRate < 60) {
      return Colors.orange;
    } else if (reportingRate < 80) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}