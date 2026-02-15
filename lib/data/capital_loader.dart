/*
 DOC: DataSource
 Title: Capital Loader
 Purpose: Loads capital-quiz questions from flag assets and capital mappings.
*/
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import 'flag_description_loader.dart';
import '../models/flag_question.dart';

const Map<String, String> _countryCapitalByNormalizedKey = {
  'afghanistan': 'Kabul',
  'albania': 'Tirana',
  'algeria': 'Algiers',
  'andorra': 'Andorra la Vella',
  'angola': 'Luanda',
  'argentina': 'Buenos Aires',
  'armenia': 'Yerevan',
  'australia': 'Canberra',
  'austria': 'Vienna',
  'azerbaijan': 'Baku',
  'bahamas': 'Nassau',
  'bahrain': 'Manama',
  'bangladesh': 'Dhaka',
  'belarus': 'Minsk',
  'belgium': 'Brussels',
  'belize': 'Belmopan',
  'benin': 'Porto-Novo',
  'bhutan': 'Thimphu',
  'bolivia': 'Sucre',
  'bosnia and herzegovina': 'Sarajevo',
  'botswana': 'Gaborone',
  'brazil': 'Brasilia',
  'brunei': 'Bandar Seri Begawan',
  'bulgaria': 'Sofia',
  'burkina faso': 'Ouagadougou',
  'burundi': 'Gitega',
  'cambodia': 'Phnom Penh',
  'cameroon': 'Yaounde',
  'canada': 'Ottawa',
  'cape verde': 'Praia',
  'central african republic': 'Bangui',
  'chad': "N'Djamena",
  'chile': 'Santiago',
  'china': 'Beijing',
  'colombia': 'Bogota',
  'comoros': 'Moroni',
  'costa rica': 'San Jose',
  'croatia': 'Zagreb',
  'cuba': 'Havana',
  'cyprus': 'Nicosia',
  'czech republic': 'Prague',
  'democratic republic of the congo': 'Kinshasa',
  'denmark': 'Copenhagen',
  'djibouti': 'Djibouti',
  'dominica': 'Roseau',
  'dominican republic': 'Santo Domingo',
  'ecuador': 'Quito',
  'egypt': 'Cairo',
  'el salvador': 'San Salvador',
  'equatorial guinea': 'Malabo',
  'eritrea': 'Asmara',
  'estonia': 'Tallinn',
  'ethiopia': 'Addis Ababa',
  'fiji': 'Suva',
  'finland': 'Helsinki',
  'france': 'Paris',
  'gabon': 'Libreville',
  'gambia': 'Banjul',
  'georgia': 'Tbilisi',
  'germany': 'Berlin',
  'ghana': 'Accra',
  'greece': 'Athens',
  'guatemala': 'Guatemala City',
  'guinea': 'Conakry',
  'guinea bissau': 'Bissau',
  'guyana': 'Georgetown',
  'haiti': 'Port-au-Prince',
  'honduras': 'Tegucigalpa',
  'hungary': 'Budapest',
  'iceland': 'Reykjavik',
  'india': 'New Delhi',
  'indonesia': 'Jakarta',
  'iran': 'Tehran',
  'iraq': 'Baghdad',
  'ireland': 'Dublin',
  'israel': 'Jerusalem',
  'italy': 'Rome',
  'jamaica': 'Kingston',
  'japan': 'Tokyo',
  'jordan': 'Amman',
  'kazakhstan': 'Astana',
  'kenya': 'Nairobi',
  'kuwait': 'Kuwait City',
  'kyrgyzstan': 'Bishkek',
  'laos': 'Vientiane',
  'latvia': 'Riga',
  'lebanon': 'Beirut',
  'lesotho': 'Maseru',
  'liberia': 'Monrovia',
  'libya': 'Tripoli',
  'lithuania': 'Vilnius',
  'luxembourg': 'Luxembourg',
  'macedonia': 'Skopje',
  'madagascar': 'Antananarivo',
  'malawi': 'Lilongwe',
  'malaysia': 'Kuala Lumpur',
  'maldives': 'Male',
  'mali': 'Bamako',
  'malta': 'Valletta',
  'mauritania': 'Nouakchott',
  'mauritius': 'Port Louis',
  'mexico': 'Mexico City',
  'moldova': 'Chisinau',
  'mongolia': 'Ulaanbaatar',
  'morocco': 'Rabat',
  'mozambique': 'Maputo',
  'myanmar': 'Naypyidaw',
  'namibia': 'Windhoek',
  'nepal': 'Kathmandu',
  'netherlands': 'Amsterdam',
  'new zealand': 'Wellington',
  'nicaragua': 'Managua',
  'niger': 'Niamey',
  'nigeria': 'Abuja',
  'north korea': 'Pyongyang',
  'norway': 'Oslo',
  'oman': 'Muscat',
  'pakistan': 'Islamabad',
  'panama': 'Panama City',
  'paraguay': 'Asuncion',
  'peru': 'Lima',
  'philippines': 'Manila',
  'poland': 'Warsaw',
  'portugal': 'Lisbon',
  'qatar': 'Doha',
  'republic of the congo': 'Brazzaville',
  'romania': 'Bucharest',
  'russia': 'Moscow',
  'rwanda': 'Kigali',
  'saudi arabia': 'Riyadh',
  'senegal': 'Dakar',
  'serbia': 'Belgrade',
  'singapore': 'Singapore',
  'slovakia': 'Bratislava',
  'slovenia': 'Ljubljana',
  'somalia': 'Mogadishu',
  'south africa': 'Pretoria',
  'south korea': 'Seoul',
  'spain': 'Madrid',
  'sri lanka': 'Sri Jayawardenepura Kotte',
  'sudan': 'Khartoum',
  'sweden': 'Stockholm',
  'switzerland': 'Bern',
  'syria': 'Damascus',
  'taiwan': 'Taipei',
  'tajikistan': 'Dushanbe',
  'tanzania': 'Dodoma',
  'thailand': 'Bangkok',
  'tunisia': 'Tunis',
  'turkey': 'Ankara',
  'uganda': 'Kampala',
  'ukraine': 'Kyiv',
  'united arab emirates': 'Abu Dhabi',
  'united kingdom': 'London',
  'united states': 'Washington, D.C.',
  'uruguay': 'Montevideo',
  'uzbekistan': 'Tashkent',
  'venezuela': 'Caracas',
  'vietnam': 'Hanoi',
  'yemen': "Sana'a",
  'zambia': 'Lusaka',
  'zimbabwe': 'Harare',
};

/// Loads capital questions by pairing known capitals with available flag assets.
Future<List<FlagQuestion>> loadAllCapitals() async {
  final manifestJson = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestJson);
  final descriptions = await loadFlagDescriptions();

  final flagPaths = manifestMap.keys
      .where((path) => path.startsWith('assets/flags/'))
      .toList();

  final questions = <FlagQuestion>[];
  for (final path in flagPaths) {
    final fileName = path.split('/').last.split('.').first;
    final countryKey = normalizeCountryKey(fileName);
    final capital = _countryCapitalByNormalizedKey[countryKey];
    if (capital == null) continue;

    questions.add(
      FlagQuestion(
        imagePath: path,
        correctAnswer: capital,
        options: const [],
        visualDescription: descriptions[countryKey],
      ),
    );
  }

  return questions;
}

/// Given all capital questions, builds randomized 4-option choices.
List<FlagQuestion> prepareCapitalQuiz(List<FlagQuestion> all) {
  if (all.length < 4) return <FlagQuestion>[];

  final rand = Random();
  final pool = List<FlagQuestion>.from(all)..shuffle(rand);

  return pool.map((q) {
    final wrongs = all.where((f) => f.correctAnswer != q.correctAnswer).toList()
      ..shuffle(rand);

    final options = <String>[
      q.correctAnswer,
      wrongs[0].correctAnswer,
      wrongs[1].correctAnswer,
      wrongs[2].correctAnswer,
    ]..shuffle(rand);

    return FlagQuestion(
      imagePath: q.imagePath,
      correctAnswer: q.correctAnswer,
      options: options,
      visualDescription: q.visualDescription,
    );
  }).toList();
}

/// Normalizes country key for lookups from mixed-case file names.
String normalizeCountryKey(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
