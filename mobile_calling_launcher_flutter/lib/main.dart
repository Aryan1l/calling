
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CallingLauncherApp());
}

class CallingLauncherApp extends StatelessWidget {
  const CallingLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calling Launcher',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090B10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String number = '';
  final List<Map<String, String>> recent = [];
  final List<String> favorites = [];
  final TextEditingController search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      favorites.addAll(p.getStringList('favorites') ?? []);
    });
  }

  Future<void> _saveFavorites() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorites', favorites);
  }

  void addDigit(String digit) {
    if (number.length >= 15) return;
    setState(() => number += digit);
  }

  void removeDigit() {
    if (number.isEmpty) return;
    setState(() => number = number.substring(0, number.length - 1));
  }

  Future<void> callNumber(String value) async {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      setState(() {
        recent.insert(0, {'name': cleaned, 'number': cleaned});
        if (recent.length > 20) recent.removeLast();
      });
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone calling is not available on this device.')),
      );
    }
  }

  void toggleFavorite(String value) {
    setState(() {
      if (favorites.contains(value)) {
        favorites.remove(value);
      } else {
        favorites.add(value);
      }
    });
    _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [
            _buildHome(),
            _buildRecents(),
            _buildFavorites(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: const Color(0xFF0E1118),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dialpad_outlined), selectedIcon: Icon(Icons.dialpad), label: 'Dial'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Recent'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Favorites'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Calling Launcher',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => _showSettings(),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141824),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: search,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => setState(() => number = v),
                    decoration: const InputDecoration(
                      hintText: 'Search or enter number',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (number.isNotEmpty)
                  IconButton(
                    onPressed: () => setState(() {
                      number = '';
                      search.clear();
                    }),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            number.isEmpty ? 'Enter a number' : number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          _dialPad(),
          const SizedBox(height: 20),
          Center(
            child: FloatingActionButton.large(
              heroTag: 'call',
              onPressed: () => callNumber(number),
              backgroundColor: const Color(0xFF28C76F),
              foregroundColor: Colors.white,
              child: const Icon(Icons.call, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialPad() {
    const keys = [
      ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
      ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
      ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
      ['*', ''], ['0', '+'], ['#', ''],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 12,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (_, i) {
        final key = keys[i];
        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            addDigit(key[0]);
            search.text = number;
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151925),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(key[0], style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w600)),
                if (key[1].isNotEmpty)
                  Text(key[1], style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecents() {
    return _listPage(
      title: 'Recent calls',
      emptyIcon: Icons.history,
      emptyText: 'No calls yet',
      items: recent,
    );
  }

  Widget _buildFavorites() {
    final items = favorites.map((n) => {'name': n, 'number': n}).toList();
    return _listPage(
      title: 'Favorites',
      emptyIcon: Icons.star_border,
      emptyText: 'No favorites yet',
      items: items,
    );
  }

  Widget _listPage({
    required String title,
    required IconData emptyIcon,
    required String emptyText,
    required List<Map<String, String>> items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(emptyIcon, size: 56, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(emptyText, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final value = item['number']!;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    tileColor: const Color(0xFF141824),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF292E45),
                      child: Text(value.substring(0, 1)),
                    ),
                    title: Text(item['name']!),
                    subtitle: Text(value),
                    trailing: IconButton(
                      onPressed: () => callNumber(value),
                      icon: const Icon(Icons.call, color: Color(0xFF28C76F)),
                    ),
                    onTap: () => callNumber(value),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151925),
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Calling Launcher'),
                subtitle: Text('Flutter Android application'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear local favorites'),
                onTap: () {
                  setState(() => favorites.clear());
                  _saveFavorites();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
