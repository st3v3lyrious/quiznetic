String toUpperCase(String strToConvert) {
  if (strToConvert.isEmpty) return 'Unknown';
  return strToConvert[0].toUpperCase() + strToConvert.substring(1);
}
