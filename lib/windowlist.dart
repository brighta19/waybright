part of './waybright.dart';

class _WindowEntryItem extends LinkedListEntry<_WindowEntryItem> {
  Window window;
  _WindowEntryItem(this.window);
}

class _WindowListIterator implements Iterator<Window> {
  final WindowList _list;
  _WindowEntryItem? _current;
  _WindowEntryItem? _next;
  bool _visitedFirst;

  _WindowListIterator(WindowList list)
      : _list = list,
        _next = list._first,
        _visitedFirst = false;

  @override
  Window get current => _current!.window;

  @override
  bool moveNext() {
    if (_list.isEmpty ||
        (_visitedFirst && identical(_next, _list.first)) ||
        _next == null) {
      _current = null;
      return false;
    }
    _visitedFirst = true;
    _current = _next;
    _next = _next!.next;
    return true;
  }
}

class _WindowListReverseIterator implements Iterator<Window> {
  final WindowList _list;
  _WindowEntryItem? _current;
  _WindowEntryItem? _next;
  bool _visitedFirst;

  _WindowListReverseIterator(WindowList list)
      : _list = list,
        _next = list._last,
        _visitedFirst = false;

  @override
  Window get current => _current!.window;

  @override
  bool moveNext() {
    if (_list.isEmpty ||
        (_visitedFirst && identical(_next, _list.last)) ||
        _next == null) {
      _current = null;
      return false;
    }
    _visitedFirst = true;
    _current = _next;
    _next = _next!.previous;
    return true;
  }
}

class _WindowListIterable extends Iterable<Window> {
  final Iterator<Window> _iterator;

  _WindowListIterable(this._iterator);

  @override
  Iterator<Window> get iterator => _iterator;
}

/// A list of windows.
///
/// This list can help create stack-based compositors, where floating windows
/// lay on top of each other.
///
/// This collection uses a [LinkedList] and a [HashMap] to achieve O(1) constant
/// time.
class WindowList {
  final _linkedList = LinkedList<_WindowEntryItem>();
  final _hashMap = HashMap<Window, _WindowEntryItem>();
  var _length = 0;

  /// Whether this list has no elements.
  bool get isEmpty => _linkedList.isEmpty;

  /// Whether this list has at least one element.
  bool get isNotEmpty => _linkedList.isNotEmpty;

  /// The number of elements in this list.
  int get length => _length;

  _WindowEntryItem? get _first => isEmpty ? null : _linkedList.first;
  _WindowEntryItem? get _last => isEmpty ? null : _linkedList.last;

  /// Returns the first element.
  ///
  /// Throws a [StateError] if this is empty. Otherwise returns the first
  /// element in this list.
  Window get first {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _first!.window;
  }

  /// Returns the last element.
  ///
  /// Throws a [StateError] if this is empty. Otherwise returns the last
  /// element in this list.
  Window get last {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _last!.window;
  }

  /// Returns a new [Iterator] that allows iterating this list from the start to
  /// the end.
  Iterable<Window> get frontToBackIterable =>
      _WindowListIterable(_WindowListIterator(this));

  /// Returns a new [Iterator] that allows iterating this list from the end to
  /// the start.
  Iterable<Window> get backToFrontIterable =>
      _WindowListIterable(_WindowListReverseIterator(this));

  /// Adds [window] to the beginning of this list.
  void addToFront(Window window) {
    var windowEntryItem = _WindowEntryItem(window);
    _linkedList.addFirst(windowEntryItem);
    _hashMap[window] = windowEntryItem;
    _length++;
  }

  /// Removes [window] from this list.
  ///
  /// Returns false and does nothing if [window] is not in this list.
  bool remove(Window window) {
    var windowEntryItem = _hashMap[window];
    if (windowEntryItem != null) {
      _linkedList.remove(windowEntryItem);
      _hashMap.remove(window);
      _length--;
      return true;
    }
    return false;
  }

  /// Moves [window] to the beginning of this list.
  ///
  /// Returns false and does nothing if [window] is not in this list.
  bool moveToFront(Window window) {
    var windowEntryItem = _hashMap[window];
    if (windowEntryItem != null) {
      _linkedList.remove(windowEntryItem);
      _linkedList.addFirst(windowEntryItem);
      return true;
    }
    return false;
  }

  /// The successor of [window] in this list.
  ///
  /// The value is null if there is no successor in this list, or if [window] is
  /// not in this list.
  Window? getNextWindow(Window window) {
    var windowEntryItem = _hashMap[window];
    return windowEntryItem?.next?.window;
  }
}
