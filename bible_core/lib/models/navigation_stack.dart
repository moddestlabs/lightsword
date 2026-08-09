import 'passage_reference.dart';

/// A stack for managing in-session Back/Forward (Undo/Redo) passage navigation.
class NavigationStack {
  final int maxHistory;
  final List<PassageReference> _history = [];
  int _currentIndex = -1;

  NavigationStack({this.maxHistory = 100});

  /// Current reference, or null if stack is empty
  PassageReference? get current =>
      _currentIndex >= 0 && _currentIndex < _history.length
          ? _history[_currentIndex]
          : null;

  /// Whether back navigation is available
  bool get canGoBack => _currentIndex > 0;

  /// Whether forward navigation (redo) is available
  bool get canGoForward =>
      _currentIndex >= 0 && _currentIndex < _history.length - 1;

  /// Push a new reference onto the stack.
  /// Clears any forward history (redo branch).
  void push(PassageReference ref) {
    if (current == ref) return; // Avoid duplicate consecutive pushes

    if (_currentIndex >= 0 && _currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(ref);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
    _currentIndex = _history.length - 1;
  }

  /// Go back one step (undo navigation).
  PassageReference? goBack() {
    if (!canGoBack) return null;
    _currentIndex--;
    return current;
  }

  /// Go forward one step (redo navigation).
  PassageReference? goForward() {
    if (!canGoForward) return null;
    _currentIndex++;
    return current;
  }

  /// Clear the navigation stack.
  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}
