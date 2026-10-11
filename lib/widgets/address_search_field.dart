import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressSearchField extends StatefulWidget {
  const AddressSearchField({
    required this.district,
    required this.onSelected,
    required this.onEdited,
    super.key,
  });

  final String district;

  // Sends the selected address back to the screen.
  final ValueChanged<String> onSelected;

  // Tells the screen that the previous address is being changed.
  final VoidCallback onEdited;

  @override
  State<AddressSearchField> createState() =>
      _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _text = TextEditingController();
  final _client = http.Client();

  Timer? _timer;

  // Helps ignore old search responses.
  int _request = 0;

  bool _busy = false;
  String? _message;

  List<Map<String, dynamic>> _results = [];

  @override
  void didUpdateWidget(covariant AddressSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear the previous district's search results.
    if (oldWidget.district != widget.district) {
      _timer?.cancel();
      _request++;

      _text.clear();
      _results = [];
      _message = null;
      _busy = false;
    }
  }

  @override
  void dispose() {
    _request++;
    _timer?.cancel();
    _client.close();
    _text.dispose();
    super.dispose();
  }

  // Called whenever the user types.
  void _changed(String value) {
    widget.onEdited();

    _timer?.cancel();
    final request = ++_request;

    setState(() {
      _results = [];
      _message = null;
      _busy = false;
    });

    if (value.trim().length < 3) return;

    // Wait briefly instead of searching on every keystroke.
    _timer = Timer(
      const Duration(milliseconds: 750),
      () => _search(value, request),
    );
  }

  Future<void> _search(String value, int request) async {
    if (!mounted || request != _request) return;

    setState(() => _busy = true);

    try {
      final response = await _client
          .get(
            Uri.https(
              'photon.komoot.io',
              '/api/',
              {
                'q':
                    '${value.trim()}, ${widget.district}, Tamil Nadu',
                'countrycode': 'IN',
                'limit': '6',
                'lang': 'en',
              },
            ),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Search unavailable');
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;

      final features = data['features'] as List? ?? [];

      // Keep only results containing valid coordinates.
      final items = features
          .whereType<Map<String, dynamic>>()
          .where((item) {
        final geometry = item['geometry'];
        final properties = item['properties'];

        if (geometry is! Map || properties is! Map) {
          return false;
        }

        final coordinates = geometry['coordinates'];

        return geometry['type'] == 'Point' &&
            coordinates is List &&
            coordinates.length >= 2 &&
            coordinates[0] is num &&
            coordinates[1] is num;
      }).toList();

      // Ignore this result if a newer search has started.
      if (!mounted || request != _request) return;

      setState(() {
        _results = items;

        _message = items.isEmpty
            ? 'No suggestions found. Try a nearby landmark '
                'or select on the map.'
            : null;
      });
    } catch (_) {
      if (!mounted || request != _request) return;

      setState(() {
        _message = 'Address search is unavailable. '
            'Check your internet and retry.';
      });
    } finally {
      if (mounted && request == _request) {
        setState(() => _busy = false);
      }
    }
  }

  // Combine available address parts into readable text.
  String _address(Map<String, dynamic> item) {
    final properties =
        item['properties'] as Map<String, dynamic>;

    return [
      properties['name'],
      properties['housenumber'],
      properties['street'],
      properties['suburb'],
      properties['district'],
      properties['city'],
      properties['county'],
      properties['state'],
      properties['postcode'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map((value) => value.toString())
        .toSet()
        .join(', ');
  }

  // Called when the user taps an address suggestion.
  void _select(Map<String, dynamic> item) {
    _timer?.cancel();
    _request++;

    final address = _address(item);
    final coordinates =
        item['geometry']['coordinates'] as List;

    _text.text = address;

    setState(() {
      _results = [];
      _busy = false;
      _message = null;
    });

    FocusScope.of(context).unfocus();

    // Keep the format used by your existing map/report screens.
    widget.onSelected(
      'Address: $address\n'
      'Latitude: ${coordinates[1]}, '
      'Longitude: ${coordinates[0]}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          onChanged: _changed,
          decoration: const InputDecoration(
            labelText: 'Search street, area or landmark',
            prefixIcon: Icon(Icons.search),
            helperText:
                'Type at least 3 characters, then choose a suggestion.',
            helperMaxLines: 2,
          ),
        ),

        if (_busy)
          const LinearProgressIndicator(),

        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_message!),
          ),

        // Scrollable list of online address suggestions.
        if (_results.isNotEmpty) ...[
          Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 280,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                    ),
                    title: Text(_address(item)),
                    onTap: () => _select(item),
                  );
                },
              ),
            ),
          ),
          const Text(
            'Address data © OpenStreetMap contributors · Photon',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ],
    );
  }
}