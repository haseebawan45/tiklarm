import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal();
  
  bool _useSystemTheme = true;
  bool _isDarkMode = false;
  
  bool get useSystemTheme => _useSystemTheme;
  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system;
    } else {
      return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  Future<void> setUseSystemTheme(bool value) async {
    if (_useSystemTheme == value) return;
    
    _useSystemTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', value);
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
  
  Future<void> toggleThemeMode() async {
    if (_useSystemTheme) {
      // First, disable system theme and use explicit mode
      await setUseSystemTheme(false);
    }
    // Then toggle between dark and light
    await setDarkMode(!_isDarkMode);
  }
  
  Future<void> refreshFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    final prevUseSystemTheme = _useSystemTheme;
    final prevIsDarkMode = _isDarkMode;
    
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    if (prevUseSystemTheme != _useSystemTheme || prevIsDarkMode != _isDarkMode) {
      notifyListeners();
    }
  }
} 