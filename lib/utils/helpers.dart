/*
 DOC: Utility
 Title: Helpers
 Purpose: Provides shared helper utilities used across the app.
*/
String toUpperCase(String strToConvert) {
  if (strToConvert.isEmpty) return 'Unknown';
  return strToConvert[0].toUpperCase() + strToConvert.substring(1);
}
