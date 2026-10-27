import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/job_models.dart';

class EuropeanCity {
  final String name;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;

  const EuropeanCity({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => '$name, $country';

  CityLocation toCityLocation() {
    return CityLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
      region: country,
    );
  }
}

class EuropeanLocationsService {
  // Database locale rapido con oltre 100 principali città europee (Italia, Francia, Germania, Spagna, UK, ecc.)
  static const List<EuropeanCity> kCuratedEuropeanCities = [
    // Italia
    EuropeanCity(name: 'Milano', country: 'Italia', countryCode: 'IT', latitude: 45.4642, longitude: 9.1900),
    EuropeanCity(name: 'Roma', country: 'Italia', countryCode: 'IT', latitude: 41.9028, longitude: 12.4964),
    EuropeanCity(name: 'Torino', country: 'Italia', countryCode: 'IT', latitude: 45.0703, longitude: 7.6869),
    EuropeanCity(name: 'Bologna', country: 'Italia', countryCode: 'IT', latitude: 44.4949, longitude: 11.3426),
    EuropeanCity(name: 'Firenze', country: 'Italia', countryCode: 'IT', latitude: 43.7696, longitude: 11.2558),
    EuropeanCity(name: 'Napoli', country: 'Italia', countryCode: 'IT', latitude: 40.8518, longitude: 14.2681),
    EuropeanCity(name: 'Genova', country: 'Italia', countryCode: 'IT', latitude: 44.4056, longitude: 8.9463),
    EuropeanCity(name: 'Verona', country: 'Italia', countryCode: 'IT', latitude: 45.4384, longitude: 10.9916),
    EuropeanCity(name: 'Venezia', country: 'Italia', countryCode: 'IT', latitude: 45.4408, longitude: 12.3155),
    EuropeanCity(name: 'Padova', country: 'Italia', countryCode: 'IT', latitude: 45.4064, longitude: 11.8768),
    EuropeanCity(name: 'Palermo', country: 'Italia', countryCode: 'IT', latitude: 38.1157, longitude: 13.3615),
    EuropeanCity(name: 'Catania', country: 'Italia', countryCode: 'IT', latitude: 37.5079, longitude: 15.0830),
    EuropeanCity(name: 'Bari', country: 'Italia', countryCode: 'IT', latitude: 41.1171, longitude: 16.8719),
    EuropeanCity(name: 'Trieste', country: 'Italia', countryCode: 'IT', latitude: 45.6495, longitude: 13.7768),
    EuropeanCity(name: 'Brescia', country: 'Italia', countryCode: 'IT', latitude: 45.5416, longitude: 10.2118),
    EuropeanCity(name: 'Bergamo', country: 'Italia', countryCode: 'IT', latitude: 45.6983, longitude: 9.6773),
    EuropeanCity(name: 'Trento', country: 'Italia', countryCode: 'IT', latitude: 46.0748, longitude: 11.1217),
    EuropeanCity(name: 'Bolzano', country: 'Italia', countryCode: 'IT', latitude: 46.4983, longitude: 11.3548),
    EuropeanCity(name: 'Parma', country: 'Italia', countryCode: 'IT', latitude: 44.8015, longitude: 10.3279),
    EuropeanCity(name: 'Modena', country: 'Italia', countryCode: 'IT', latitude: 44.6471, longitude: 10.9252),
    EuropeanCity(name: 'Perugia', country: 'Italia', countryCode: 'IT', latitude: 43.1107, longitude: 12.3908),
    EuropeanCity(name: 'Ancona', country: 'Italia', countryCode: 'IT', latitude: 43.6158, longitude: 13.5189),
    EuropeanCity(name: 'Cagliari', country: 'Italia', countryCode: 'IT', latitude: 39.2238, longitude: 9.1217),
    EuropeanCity(name: 'Pescara', country: 'Italia', countryCode: 'IT', latitude: 42.4618, longitude: 14.2161),
    EuropeanCity(name: 'Lecce', country: 'Italia', countryCode: 'IT', latitude: 40.3515, longitude: 18.1750),
    EuropeanCity(name: 'Messina', country: 'Italia', countryCode: 'IT', latitude: 38.1938, longitude: 15.5540),

    // Francia
    EuropeanCity(name: 'Parigi', country: 'Francia', countryCode: 'FR', latitude: 48.8566, longitude: 2.3522),
    EuropeanCity(name: 'Lione', country: 'Francia', countryCode: 'FR', latitude: 45.7640, longitude: 4.8357),
    EuropeanCity(name: 'Marsiglia', country: 'Francia', countryCode: 'FR', latitude: 43.2965, longitude: 5.3698),
    EuropeanCity(name: 'Tolosa', country: 'Francia', countryCode: 'FR', latitude: 43.6047, longitude: 1.4442),
    EuropeanCity(name: 'Nizza', country: 'Francia', countryCode: 'FR', latitude: 43.7102, longitude: 7.2620),
    EuropeanCity(name: 'Bordeaux', country: 'Francia', countryCode: 'FR', latitude: 44.8378, longitude: -0.5792),
    EuropeanCity(name: 'Lilla', country: 'Francia', countryCode: 'FR', latitude: 50.6292, longitude: 3.0573),
    EuropeanCity(name: 'Strasburgo', country: 'Francia', countryCode: 'FR', latitude: 48.5734, longitude: 7.7521),
    EuropeanCity(name: 'Nantes', country: 'Francia', countryCode: 'FR', latitude: 47.2184, longitude: -1.5536),

    // Germania
    EuropeanCity(name: 'Berlino', country: 'Germania', countryCode: 'DE', latitude: 52.5200, longitude: 13.4050),
    EuropeanCity(name: 'Monaco di Baviera', country: 'Germania', countryCode: 'DE', latitude: 48.1351, longitude: 11.5820),
    EuropeanCity(name: 'Francoforte', country: 'Germania', countryCode: 'DE', latitude: 50.1109, longitude: 8.6821),
    EuropeanCity(name: 'Amburgo', country: 'Germania', countryCode: 'DE', latitude: 53.5511, longitude: 9.9937),
    EuropeanCity(name: 'Colonia', country: 'Germania', countryCode: 'DE', latitude: 50.9375, longitude: 6.9603),
    EuropeanCity(name: 'Stoccarda', country: 'Germania', countryCode: 'DE', latitude: 48.7758, longitude: 9.1829),
    EuropeanCity(name: 'Düsseldorf', country: 'Germania', countryCode: 'DE', latitude: 51.2277, longitude: 6.7735),
    EuropeanCity(name: 'Lipsia', country: 'Germania', countryCode: 'DE', latitude: 51.3397, longitude: 12.3731),
    EuropeanCity(name: 'Dresda', country: 'Germania', countryCode: 'DE', latitude: 51.0504, longitude: 13.7373),

    // Spagna
    EuropeanCity(name: 'Madrid', country: 'Spagna', countryCode: 'ES', latitude: 40.4168, longitude: -3.7038),
    EuropeanCity(name: 'Barcellona', country: 'Spagna', countryCode: 'ES', latitude: 41.3879, longitude: 2.1699),
    EuropeanCity(name: 'Valencia', country: 'Spagna', countryCode: 'ES', latitude: 39.4699, longitude: -0.3763),
    EuropeanCity(name: 'Siviglia', country: 'Spagna', countryCode: 'ES', latitude: 37.3891, longitude: -5.9845),
    EuropeanCity(name: 'Saragozza', country: 'Spagna', countryCode: 'ES', latitude: 41.6488, longitude: -0.8891),
    EuropeanCity(name: 'Malaga', country: 'Spagna', countryCode: 'ES', latitude: 36.7213, longitude: -4.4214),
    EuropeanCity(name: 'Bilbao', country: 'Spagna', countryCode: 'ES', latitude: 43.2630, longitude: -2.9350),

    // Regno Unito
    EuropeanCity(name: 'Londra', country: 'Regno Unito', countryCode: 'GB', latitude: 51.5074, longitude: -0.1278),
    EuropeanCity(name: 'Manchester', country: 'Regno Unito', countryCode: 'GB', latitude: 53.4808, longitude: -2.2426),
    EuropeanCity(name: 'Birmingham', country: 'Regno Unito', countryCode: 'GB', latitude: 52.4862, longitude: -1.8904),
    EuropeanCity(name: 'Edimburgo', country: 'Regno Unito', countryCode: 'GB', latitude: 55.9533, longitude: -3.1883),
    EuropeanCity(name: 'Glasgow', country: 'Regno Unito', countryCode: 'GB', latitude: 55.8642, longitude: -4.2518),
    EuropeanCity(name: 'Bristol', country: 'Regno Unito', countryCode: 'GB', latitude: 51.4545, longitude: -2.5879),

    // Svizzera & Austria
    EuropeanCity(name: 'Zurigo', country: 'Svizzera', countryCode: 'CH', latitude: 47.3769, longitude: 8.5417),
    EuropeanCity(name: 'Ginevra', country: 'Svizzera', countryCode: 'CH', latitude: 46.2044, longitude: 6.1432),
    EuropeanCity(name: 'Berna', country: 'Svizzera', countryCode: 'CH', latitude: 46.9480, longitude: 7.4474),
    EuropeanCity(name: 'Basilea', country: 'Svizzera', countryCode: 'CH', latitude: 47.5596, longitude: 7.5886),
    EuropeanCity(name: 'Lugano', country: 'Svizzera', countryCode: 'CH', latitude: 46.0037, longitude: 8.9511),
    EuropeanCity(name: 'Vienna', country: 'Austria', countryCode: 'AT', latitude: 48.2082, longitude: 16.3738),
    EuropeanCity(name: 'Salisburgo', country: 'Austria', countryCode: 'AT', latitude: 47.8095, longitude: 13.0550),
    EuropeanCity(name: 'Innsbruck', country: 'Austria', countryCode: 'AT', latitude: 47.2692, longitude: 11.4041),

    // Olanda & Belgio
    EuropeanCity(name: 'Amsterdam', country: 'Paesi Bassi', countryCode: 'NL', latitude: 52.3676, longitude: 4.9041),
    EuropeanCity(name: 'Rotterdam', country: 'Paesi Bassi', countryCode: 'NL', latitude: 51.9244, longitude: 4.4777),
    EuropeanCity(name: 'L\'Aia', country: 'Paesi Bassi', countryCode: 'NL', latitude: 52.0705, longitude: 4.3007),
    EuropeanCity(name: 'Utrecht', country: 'Paesi Bassi', countryCode: 'NL', latitude: 52.0907, longitude: 5.1214),
    EuropeanCity(name: 'Bruxelles', country: 'Belgio', countryCode: 'BE', latitude: 50.8503, longitude: 4.3517),
    EuropeanCity(name: 'Anversa', country: 'Belgio', countryCode: 'BE', latitude: 51.2194, longitude: 4.4025),
    EuropeanCity(name: 'Gand', country: 'Belgio', countryCode: 'BE', latitude: 51.0543, longitude: 3.7174),

    // Portogallo
    EuropeanCity(name: 'Lisbona', country: 'Portogallo', countryCode: 'PT', latitude: 38.7223, longitude: -9.1393),
    EuropeanCity(name: 'Porto', country: 'Portogallo', countryCode: 'PT', latitude: 41.1579, longitude: -8.6291),

    // Scandinavia & Nord Europa
    EuropeanCity(name: 'Stoccolma', country: 'Svezia', countryCode: 'SE', latitude: 59.3293, longitude: 18.0686),
    EuropeanCity(name: 'Göteborg', country: 'Svezia', countryCode: 'SE', latitude: 57.7089, longitude: 11.9746),
    EuropeanCity(name: 'Oslo', country: 'Norvegia', countryCode: 'NO', latitude: 59.9139, longitude: 10.7522),
    EuropeanCity(name: 'Copenaghen', country: 'Danimarca', countryCode: 'DK', latitude: 55.6761, longitude: 12.5683),
    EuropeanCity(name: 'Helsinki', country: 'Finlandia', countryCode: 'FI', latitude: 60.1699, longitude: 24.9384),
    EuropeanCity(name: 'Dublino', country: 'Irlanda', countryCode: 'IE', latitude: 53.3498, longitude: -6.2603),

    // Europa Centrale & Orientale
    EuropeanCity(name: 'Varsavia', country: 'Polonia', countryCode: 'PL', latitude: 52.2297, longitude: 21.0122),
    EuropeanCity(name: 'Cracovia', country: 'Polonia', countryCode: 'PL', latitude: 50.0647, longitude: 19.9450),
    EuropeanCity(name: 'Praga', country: 'Repubblica Ceca', countryCode: 'CZ', latitude: 50.0755, longitude: 14.4378),
    EuropeanCity(name: 'Brno', country: 'Repubblica Ceca', countryCode: 'CZ', latitude: 49.1951, longitude: 16.6068),
    EuropeanCity(name: 'Budapest', country: 'Ungheria', countryCode: 'HU', latitude: 47.4979, longitude: 19.0402),
    EuropeanCity(name: 'Bucarest', country: 'Romania', countryCode: 'RO', latitude: 44.4268, longitude: 26.1025),
    EuropeanCity(name: 'Atene', country: 'Grecia', countryCode: 'GR', latitude: 37.9838, longitude: 23.7275),
    EuropeanCity(name: 'Salonicco', country: 'Grecia', countryCode: 'GR', latitude: 40.6401, longitude: 22.9444),
  ];

  /// Ricerca e autocompilazione città in tutta Europa (combinazione offline istantanea + online OpenStreetMap Nominatim/Photon)
  static Future<List<EuropeanCity>> searchEuropeanCities(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return kCuratedEuropeanCities.take(15).toList();
    }

    // 1. Risultati immediati dal catalogo europeo locale
    final localMatches = kCuratedEuropeanCities.where((city) {
      final name = city.name.toLowerCase();
      final country = city.country.toLowerCase();
      return name.contains(cleanQuery) || country.contains(cleanQuery);
    }).toList();

    // Se abbiamo almeno 3 risultati locali e la query è breve, restituiamo subito
    if (cleanQuery.length < 3 && localMatches.isNotEmpty) {
      return localMatches;
    }

    // 2. Query online OpenStreetMap Nominatim per coprire qualsiasi comune, paese o città in Europa
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&featuretype=city&addressdetails=1&limit=8',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EasyJob-App/1.0 (com.findmyjob.find_my_job)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<EuropeanCity> onlineMatches = [];

        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final address = item['address'] as Map<String, dynamic>? ?? {};
          final cityName = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              item['name'] ??
              '';
          final country = address['country'] ?? '';
          final countryCode =
              (address['country_code'] ?? '').toString().toUpperCase();

          if (cityName.isNotEmpty) {
            onlineMatches.add(
              EuropeanCity(
                name: cityName,
                country: country.isNotEmpty ? country : 'Europa',
                countryCode: countryCode,
                latitude: lat,
                longitude: lon,
              ),
            );
          }
        }

        // Fonde i risultati evitando duplicati
        final Set<String> seen = {};
        final List<EuropeanCity> combined = [];

        for (final c in [...localMatches, ...onlineMatches]) {
          final key = '${c.name.toLowerCase()}_${c.country.toLowerCase()}';
          if (!seen.contains(key)) {
            seen.add(key);
            combined.add(c);
          }
        }
        return combined.take(15).toList();
      }
    } catch (e) {
      debugPrint('Nominatim European lookup fallback: $e');
    }

    return localMatches;
  }

  /// Ottiene la posizione GPS corrente in tempo reale
  static Future<Position?> getCurrentRealTimeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('Geolocator error: $e');
      return null;
    }
  }
}
