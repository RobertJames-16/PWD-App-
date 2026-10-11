import 'dart:async';

import 'package:flutter/material.dart';

import '../services/pwd_place_service.dart';

class PwdLocations {
  static const Map<String, String> districts = {
    'ARI': 'Ariyalur',
    'CHE': 'Chengalpattu',
    'CHN': 'Chennai',
    'COI': 'Coimbatore',
    'CUD': 'Cuddalore',
    'DHA': 'Dharmapuri',
    'DIN': 'Dindigul',
    'ERD': 'Erode',
    'KAL': 'Kallakurichi',
    'KAN': 'Kancheepuram',
    'KAR': 'Karur',
    'KRI': 'Krishnagiri',
    'MDU': 'Madurai',
    'MAY': 'Mayiladuthurai',
    'NAG': 'Nagapattinam',
    'KAN_CITY': 'Kanniyakumari',
    'NAM': 'Namakkal',
    'NIL': 'Nilgiris',
    'PER': 'Perambalur',
    'PUD': 'Pudukkottai',
    'RAM': 'Ramanathapuram',
    'RPT': 'Ranipet',
    'SAL': 'Salem',
    'SIV': 'Sivaganga',
    'TEN': 'Tenkasi',
    'THA': 'Thanjavur',
    'THE': 'Theni',
    'THO': 'Thoothukudi',
    'TIR': 'Tiruchirappalli',
    'TIRU': 'Tirunelveli',
    'TIRUP': 'Tiruppur',
    'TIRUV': 'Tiruvallur',
    'TIRUVAN': 'Tiruvannamalai',
    'TPT': 'Tirupathur',
    'TVR': 'Tiruvarur',
    'VEL': 'Vellore',
    'VIL': 'Viluppuram',
    'VIR': 'Virudhunagar',
  };

  // Offline suggestions: district taluks and selected popular areas.
  // Online map search is still used for streets and landmarks.
  static const Map<String, List<String>> commonAreas = {
    'ARI': [
      'Ariyalur',
      'Andimadam',
      'Sendurai',
      'Udayarpalayam',
      'Jayankondam',
    ],
    'CHE': [
      'Chengalpattu',
      'Cheyyur',
      'Madurantakam',
      'Pallavaram',
      'Tambaram',
      'Thirukalukundram',
      'Tiruporur',
      'Vandalur',
    ],
    'CHE_CITY': [
      'Alandur',
      'Ambattur',
      'Aminjikarai',
      'Ayanavaram',
      'Adyar',
      'Anna Nagar',
      'Besant Nagar',
      'Chromepet',
      'Egmore',
      'Guindy',
      'Kolathur',
      'Kodambakkam',
      'Madhavaram',
      'Maduravoyal',
      'Mambalam',
      'Mylapore',
      'Nungambakkam',
      'Perambur',
      'Porur',
      'Purasawalkam',
      'Sholinganallur',
      'T. Nagar',
      'Tambaram',
      'Tondiarpet',
      'Tiruvottiyur',
      'Velachery',
    ],
    'COI': [
      'Anaimalai',
      'Annur',
      'Coimbatore North',
      'Coimbatore South',
      'Kinathukadavu',
      'Madukkarai',
      'Mettupalayam',
      'Perur',
      'Pollachi',
      'Sulur',
      'Valparai',
      'Gandhipuram',
      'RS Puram',
      'Peelamedu',
      'Singanallur',
      'Saibaba Colony',
      'Vadavalli',
      'Saravanampatti',
    ],
    'CUD': [
      'Cuddalore',
      'Bhuvanagiri',
      'Chidambaram',
      'Kattumannarkoil',
      'Kurinjipadi',
      'Panruti',
      'Srimushnam',
      'Thittakudi',
      'Veppur',
      'Virudhachalam',
    ],
    'DHA': [
      'Dharmapuri',
      'Harur',
      'Karimangalam',
      'Nallampalli',
      'Palacode',
      'Pappireddipatti',
      'Pennagaram',
    ],
    'DIN': [
      'Dindigul East',
      'Dindigul West',
      'Athoor',
      'Guziliamparai',
      'Kodaikanal',
      'Natham',
      'Nilakottai',
      'Oddanchatram',
      'Palani',
      'Vedasandur',
    ],
    'ERD': [
      'Erode',
      'Anthiyur',
      'Bhavani',
      'Gobichettipalayam',
      'Kodumudi',
      'Modakurichi',
      'Nambiyur',
      'Perundurai',
      'Sathyamangalam',
      'Thalavadi',
    ],
    'KAL': [
      'Kallakurichi',
      'Chinnasalem',
      'Kalvarayan Hills',
      'Sankarapuram',
      'Tirukoilur',
      'Ulundurpet',
    ],
    'KAN': [
      'Kancheepuram',
      'Kundrathur',
      'Sriperumbudur',
      'Uthiramerur',
      'Walajabad',
    ],
    'KAN_CITY': [
      'Agastheeswaram',
      'Kalkulam',
      'Killiyur',
      'Thiruvattar',
      'Thovalai',
      'Vilavancode',
    ],
    'KAR': [
      'Karur',
      'Aravakurichi',
      'Kadavur',
      'Krishnarayapuram',
      'Kulithalai',
      'Manmangalam',
      'Pugalur',
    ],
    'KRI': [
      'Krishnagiri',
      'Anjetty',
      'Bargur',
      'Hosur',
      'Pochampalli',
      'Shoolagiri',
      'Denkanikottai',
      'Uthangarai',
    ],
    'MAD': [
      'Kallikudi',
      'Madurai East',
      'Madurai North',
      'Madurai South',
      'Madurai West',
      'Melur',
      'Peraiyur',
      'Thirumangalam',
      'Thiruparankundram',
      'Usilampatti',
      'Vadipatti',
      'Anna Nagar',
      'KK Nagar',
      'Mattuthavani',
      'Tallakulam',
      'Thirunagar',
      'Simmakkal',
    ],
    'MAY': [
      'Mayiladuthurai',
      'Kuthalam',
      'Sirkazhi',
      'Tharangambadi',
    ],
    'NAG': [
      'Nagapattinam',
      'Kilvelur',
      'Thirukkuvalai',
      'Vedaranyam',
    ],
    'NAM': [
      'Namakkal',
      'Kolli Hills',
      'Kumarapalayam',
      'Mohanur',
      'Paramathi Velur',
      'Rasipuram',
      'Senthamangalam',
      'Tiruchengode',
    ],
    'NIL': [
      'Udhagamandalam',
      'Coonoor',
      'Gudalur',
      'Kotagiri',
      'Kundah',
      'Pandalur',
    ],
    'PER': [
      'Perambalur',
      'Alathur',
      'Kunnam',
      'Veppanthattai',
    ],
    'PUD': [
      'Pudukkottai',
      'Alangudi',
      'Aranthangi',
      'Avudaiyarkoil',
      'Gandarvakkottai',
      'Iluppur',
      'Karambakudi',
      'Kulathur',
      'Manamelkudi',
      'Ponnamaravathi',
      'Thirumayam',
      'Viralimalai',
    ],
    'RAM': [
      'Ramanathapuram',
      'Kadaladi',
      'Kamuthi',
      'Kilakarai',
      'Mudukulathur',
      'Paramakudi',
      'Rajasingamangalam',
      'Rameswaram',
      'Tiruvadanai',
    ],
    'RPT': [
      'Arakkonam',
      'Arcot',
      'Kalavai',
      'Nemili',
      'Sholinghur',
      'Walajah',
    ],
    'SAL': [
      'Salem',
      'Attur',
      'Edappadi',
      'Gangavalli',
      'Kadaiyampatti',
      'Mettur',
      'Omalur',
      'Pethanaickenpalayam',
      'Salem South',
      'Salem West',
      'Sankari',
      'Vazhapadi',
      'Yercaud',
      'Hasthampatti',
      'Fairlands',
      'Ammapet',
      'Shevapet',
      'Suramangalam',
    ],
    'SIV': [
      'Sivaganga',
      'Devakottai',
      'Ilayangudi',
      'Kalaiyarkovil',
      'Karaikudi',
      'Manamadurai',
      'Singampunari',
      'Thiruppuvanam',
      'Tirupathur',
    ],
    'TEN': [
      'Tenkasi',
      'Alangulam',
      'Kadayanallur',
      'Sankarankovil',
      'Shenkottai',
      'Sivagiri',
      'Thiruvenkatam',
      'Veerakeralampudur',
    ],
    'THA': [
      'Thanjavur',
      'Boothalur',
      'Kumbakonam',
      'Orathanadu',
      'Papanasam',
      'Pattukkottai',
      'Peravurani',
      'Thiruvaiyaru',
      'Thiruvidaimaruthur',
    ],
    'THE': [
      'Theni',
      'Andipatti',
      'Bodinayakanur',
      'Periyakulam',
      'Uthamapalayam',
    ],
    'THO': [
      'Thoothukudi',
      'Eral',
      'Ettayapuram',
      'Kayathar',
      'Kovilpatti',
      'Ottapidaram',
      'Sathankulam',
      'Srivaikundam',
      'Tiruchendur',
      'Vilathikulam',
    ],
    'TIR': [
      'Lalgudi',
      'Manachanallur',
      'Manapparai',
      'Marungapuri',
      'Musiri',
      'Srirangam',
      'Thottiyam',
      'Thuraiyur',
      'Tiruchirappalli East',
      'Tiruchirappalli West',
      'Thiruverumbur',
      'Woraiyur',
      'Thillai Nagar',
      'Cantonment',
      'KK Nagar',
    ],
    'TIRU': [
      'Tirunelveli',
      'Ambasamudram',
      'Cheranmahadevi',
      'Manur',
      'Nanguneri',
      'Palayamkottai',
      'Radhapuram',
      'Thisayanvilai',
    ],
    'TPT': [
      'Tirupathur',
      'Ambur',
      'Natrampalli',
      'Vaniyambadi',
    ],
    'TIRUP': [
      'Avinashi',
      'Dharapuram',
      'Kangeyam',
      'Madathukulam',
      'Oothukuli',
      'Palladam',
      'Tiruppur North',
      'Tiruppur South',
      'Udumalaipettai',
    ],
    'TIRUV': [
      'Tiruvallur',
      'Avadi',
      'Gummidipoondi',
      'Pallipattu',
      'Ponneri',
      'Poonamallee',
      'R.K. Pet',
      'Tiruttani',
      'Uthukkottai',
    ],
    'TIRUVAN': [
      'Tiruvannamalai',
      'Arani',
      'Chengam',
      'Chetpet',
      'Cheyyar',
      'Jamunamarathur',
      'Kalasapakkam',
      'Kilpennathur',
      'Polur',
      'Thandarampattu',
      'Vandavasi',
      'Vembakkam',
    ],
    'TVR': [
      'Tiruvarur',
      'Kodavasal',
      'Koothanallur',
      'Mannargudi',
      'Nannilam',
      'Needamangalam',
      'Thiruthuraipoondi',
      'Valangaiman',
    ],
    'VEL': [
      'Vellore',
      'Anaicut',
      'Gudiyatham',
      'K.V. Kuppam',
      'Katpadi',
      'Pernambut',
    ],
    'VIL': [
      'Viluppuram',
      'Gingee',
      'Kandachipuram',
      'Marakkanam',
      'Melmalayanur',
      'Thiruvennainallur',
      'Tindivanam',
      'Vanur',
      'Vikravandi',
    ],
    'VIR': [
      'Virudhunagar',
      'Aruppukkottai',
      'Kariapatti',
      'Rajapalayam',
      'Sattur',
      'Sivakasi',
      'Srivilliputhur',
      'Tiruchuli',
      'Vembakottai',
      'Watrap',
    ],
  };

  static List<String> areasFor(String code) {
    final areas = commonAreas[code];

    if (areas == null) {
      return ['Other area'];
    }

    return [
      ...areas,
      'Other area',
    ];
  }

  static String? districtCodeFromName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final input = value.trim().toLowerCase();

    for (final entry in districts.entries) {
      if (entry.value.toLowerCase() == input) {
        return entry.key;
      }
    }

    const aliases = <String, String>{
      'chennai': 'CHE_CITY',
      'chennai city': 'CHE_CITY',
      'chengalpattu': 'CHE',
      'kanchipuram': 'KAN',
      'kanyakumari': 'KAN_CITY',
      'kanniyakumari': 'KAN_CITY',
      'trichy': 'TIR',
      'trichy city': 'TIR',
      'tiruchirappalli': 'TIR',
      'madurai': 'MAD',
      'coimbatore': 'COI',
      'salem': 'SAL',
      'tirunelveli': 'TIRU',
      'vellore': 'VEL',
      'erode': 'ERD',
      'tiruppur': 'TIRUP',
      'ranipet': 'RPT',
      'tirupathur': 'TPT',
      'tiruvarur': 'TVR',
    };

    return aliases[input];
  }

  // Officer ID validation used by AuthScreen.
  static String? validateOfficerId(String? value) {
    final id = value?.trim().toUpperCase() ?? '';

    if (id.isEmpty) {
      return 'Enter your Officer ID.';
    }

    final pattern = RegExp(
      r'^PWD-TN-[A-Z]+-\d{4}$',
    );

    if (!pattern.hasMatch(id)) {
      return 'Use format: PWD-TN-district code-4 digits.';
    }

    return null;
  }
}

class PwdAreaSelection {
  const PwdAreaSelection({
    required this.districtCode,
    required this.locality,
    this.location,
    this.fullAddress,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
  });

  final String districtCode;
  final String locality;

  final String? location;
  final String? fullAddress;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;

  String get districtName {
    return PwdLocations.districts[districtCode] ?? '';
  }

  String get label {
    if (districtName.isEmpty) {
      return locality;
    }

    return '$locality, $districtName';
  }

  String get displayLocation {
    if (fullAddress != null && fullAddress!.trim().isNotEmpty) {
      return fullAddress!;
    }

    if (location != null && location!.trim().isNotEmpty) {
      return location!;
    }

    return label;
  }
}

class PwdLocationFields extends StatefulWidget {
  const PwdLocationFields({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.lockDistrict = false,
  });

  final ValueChanged<PwdAreaSelection?> onChanged;
  final PwdAreaSelection? initialValue;
  final bool lockDistrict;

  @override
  State<PwdLocationFields> createState() => _PwdLocationFieldsState();
}

class _PwdLocationFieldsState extends State<PwdLocationFields> {
  late String _districtCode;
  late TextEditingController _textController;

  Timer? _searchTimer;

  List<PwdPlace> _suggestions = [];

  bool _searching = false;
  bool _showSuggestions = false;

  PwdAreaSelection? _selectedLocation;

  @override
  void initState() {
    super.initState();

    _districtCode = widget.initialValue?.districtCode ?? '';

    _textController = TextEditingController(
      text: widget.initialValue?.locality ?? '',
    );

    _selectedLocation = widget.initialValue;

    _textController.addListener(_edited);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _textController.removeListener(_edited);
    _textController.dispose();

    super.dispose();
  }

  void _edited() {
    final query = _textController.text.trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = null;
      _showSuggestions = query.isNotEmpty;
    });

    _searchTimer?.cancel();

    if (query.isEmpty) {
      _suggestions = [];
      widget.onChanged(null);
      return;
    }

    _searchTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        _searchPlaces(query);
      },
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final places = await PwdPlaceService.search(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = places;
        _showSuggestions = true;
      });
    } catch (error) {
      debugPrint('[PWD location fields] Search error: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = [];
        _showSuggestions = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  void _chooseOnline(PwdPlace place) {
    final name = place.name.trim();

    if (name.isEmpty) {
      return;
    }

    final address = place.locationText.trim();

    final detectedDistrict = _detectDistrictFromText(address);

    String finalDistrict = _districtCode;

    if (!widget.lockDistrict && detectedDistrict != null) {
      finalDistrict = detectedDistrict;
    }

    final selection = PwdAreaSelection(
      districtCode: finalDistrict,
      locality: name,
      location: address.isEmpty ? name : address,
      fullAddress: address.isEmpty ? name : address,
    );

    setState(() {
      _districtCode = finalDistrict;

      _selectedLocation = selection;

      _textController.value = TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(
          offset: name.length,
        ),
      );

      _suggestions = [];
      _showSuggestions = false;
    });

    widget.onChanged(selection);
  }

  String? _detectDistrictFromText(String text) {
    final lower = text.toLowerCase();

    for (final entry in PwdLocations.districts.entries) {
      if (lower.contains(entry.value.toLowerCase())) {
        return entry.key;
      }
    }

    return PwdLocations.districtCodeFromName(text);
  }

  void _useTypedLocality() {
    final query = _textController.text.trim();

    if (query.isEmpty) {
      return;
    }

    // Keep the complete address the user typed.
    final detectedDistrict = _detectDistrictFromText(query);

    String finalDistrict = _districtCode;

    if (!widget.lockDistrict && detectedDistrict != null) {
      finalDistrict = detectedDistrict;
    }

    final selection = PwdAreaSelection(
      districtCode: finalDistrict,
      locality: query,
      location: query,
      fullAddress: query,
    );

    setState(() {
      _districtCode = finalDistrict;
      _selectedLocation = selection;
      _showSuggestions = false;
      _suggestions = [];
    });

    widget.onChanged(selection);
  }

  void _districtChanged(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _districtCode = value;
      _selectedLocation = null;
    });

    final locality = _textController.text.trim();

    if (locality.isEmpty) {
      widget.onChanged(null);
      return;
    }

    widget.onChanged(
      PwdAreaSelection(
        districtCode: value,
        locality: locality,
        location: locality,
        fullAddress: locality,
      ),
    );
  }

  void _selectCommonArea(String area) {
    _searchTimer?.cancel();

    _textController.value = TextEditingValue(
      text: area,
      selection: TextSelection.collapsed(
        offset: area.length,
      ),
    );

    final selection = PwdAreaSelection(
      districtCode: _districtCode,
      locality: area,
      location: area,
      fullAddress: area,
    );

    setState(() {
      _selectedLocation = selection;
      _showSuggestions = false;
      _suggestions = [];
    });

    widget.onChanged(selection);
  }

  @override
  Widget build(BuildContext context) {
    final areas = PwdLocations.areasFor(_districtCode);
    final typedQuery = _textController.text.trim().toLowerCase();

    final localMatches = typedQuery.length < 2
        ? <String>[]
        : areas
            .where((area) => area != 'Other area')
            .where((area) => area.toLowerCase().contains(typedQuery))
            .take(8)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _districtCode.isEmpty ? null : _districtCode,
          decoration: const InputDecoration(
            labelText: 'District',
            border: OutlineInputBorder(),
          ),
          items: PwdLocations.districts.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: widget.lockDistrict ? null : _districtChanged,
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _textController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Address / Area / Locality',
            hintText: 'Type your full address',
            border: const OutlineInputBorder(),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Search address',
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      final query = _textController.text.trim();

                      if (query.isNotEmpty) {
                        _searchPlaces(query);
                      }
                    },
                  ),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Type your full address. You can select a suggestion or use the address you entered.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        if (_showSuggestions) ...[
          const SizedBox(height: 8),

          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (localMatches.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'District taluks and popular areas',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...localMatches.map(
                    (area) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(area),
                      subtitle: Text(
                        PwdLocations.districts[_districtCode] ?? '',
                      ),
                      onTap: () => _selectCommonArea(area),
                    ),
                  ),
                ],

                if (_suggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Places and addresses from the map',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ..._suggestions.map(
                    (place) => ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        place.locationText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _chooseOnline(place),
                    ),
                  ),
                ],

                if (_suggestions.isEmpty && !_searching)
                  ListTile(
                    leading: const Icon(Icons.edit_location_alt),
                    title: Text(
                      'Use "${_textController.text.trim()}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Save this address manually'),
                    onTap: _useTypedLocality,
                  ),
              ],
            ),
          ),
        ],

        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FFF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Location selected',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  _selectedLocation!.displayLocation,
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 8),

                if (_selectedLocation!.locality.isNotEmpty)
                  Text('Area / Locality: ${_selectedLocation!.locality}'),

                if (_selectedLocation!.districtName.isNotEmpty)
                  Text('District: ${_selectedLocation!.districtName}'),
              ],
            ),
          ),
        ],

        if (_districtCode.isNotEmpty && areas.length > 1) ...[
          const SizedBox(height: 16),

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Browse district taluks and areas (${areas.length - 1})',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            children: [
              SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: areas.length - 1,
                  itemBuilder: (context, index) {
                    final area = areas[index];

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(area),
                      onTap: () => _selectCommonArea(area),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}