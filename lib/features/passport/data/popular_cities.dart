class PopularCity {
  final String name;
  final String country;
  final String countryCode;
  final String flag;
  final double lat;
  final double lng;

  const PopularCity({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.lat,
    required this.lng,
  });
}

const popularCities = <PopularCity>[
  PopularCity(name: 'Paris', country: 'France', countryCode: 'FR', flag: '🇫🇷', lat: 48.8566, lng: 2.3522),
  PopularCity(name: 'London', country: 'United Kingdom', countryCode: 'GB', flag: '🇬🇧', lat: 51.5074, lng: -0.1278),
  PopularCity(name: 'New York', country: 'United States', countryCode: 'US', flag: '🇺🇸', lat: 40.7128, lng: -74.0060),
  PopularCity(name: 'Tokyo', country: 'Japan', countryCode: 'JP', flag: '🇯🇵', lat: 35.6762, lng: 139.6503),
  PopularCity(name: 'Dubai', country: 'UAE', countryCode: 'AE', flag: '🇦🇪', lat: 25.2048, lng: 55.2708),
  PopularCity(name: 'Barcelona', country: 'Spain', countryCode: 'ES', flag: '🇪🇸', lat: 41.3851, lng: 2.1734),
  PopularCity(name: 'Rome', country: 'Italy', countryCode: 'IT', flag: '🇮🇹', lat: 41.9028, lng: 12.4964),
  PopularCity(name: 'Istanbul', country: 'Turkey', countryCode: 'TR', flag: '🇹🇷', lat: 41.0082, lng: 28.9784),
  PopularCity(name: 'Berlin', country: 'Germany', countryCode: 'DE', flag: '🇩🇪', lat: 52.5200, lng: 13.4050),
  PopularCity(name: 'Amsterdam', country: 'Netherlands', countryCode: 'NL', flag: '🇳🇱', lat: 52.3676, lng: 4.9041),
  PopularCity(name: 'Bangkok', country: 'Thailand', countryCode: 'TH', flag: '🇹🇭', lat: 13.7563, lng: 100.5018),
  PopularCity(name: 'Sydney', country: 'Australia', countryCode: 'AU', flag: '🇦🇺', lat: -33.8688, lng: 151.2093),
  PopularCity(name: 'Seoul', country: 'South Korea', countryCode: 'KR', flag: '🇰🇷', lat: 37.5665, lng: 126.9780),
  PopularCity(name: 'Singapore', country: 'Singapore', countryCode: 'SG', flag: '🇸🇬', lat: 1.3521, lng: 103.8198),
  PopularCity(name: 'São Paulo', country: 'Brazil', countryCode: 'BR', flag: '🇧🇷', lat: -23.5505, lng: -46.6333),
  PopularCity(
    name: 'Buenos Aires',
    country: 'Argentina',
    countryCode: 'AR',
    flag: '🇦🇷',
    lat: -34.6037,
    lng: -58.3816,
  ),
  PopularCity(name: 'Lisbon', country: 'Portugal', countryCode: 'PT', flag: '🇵🇹', lat: 38.7223, lng: -9.1393),
  PopularCity(name: 'Prague', country: 'Czech Republic', countryCode: 'CZ', flag: '🇨🇿', lat: 50.0755, lng: 14.4378),
];
