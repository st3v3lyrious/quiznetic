// Browser bridge is installed before Flutter/Firebase initialization.
import 'dart:js_interop';

@JS('quizneticAnalytics.load')
external JSPromise<JSAny?> _load();
@JS('quizneticAnalytics.disable')
external void _disable();
@JS('quizneticAnalytics.reload')
external void _reload();

Future<void> loadAnalytics() async => await _load().toDart;
void disableAnalytics() => _disable();
void reloadWithoutAnalytics() => _reload();
