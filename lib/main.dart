import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  runApp(const JobScheduleApp());
}

class JobScheduleApp extends StatelessWidget {
  const JobScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Schedule Generator',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const JobScheduleHomePage(),
    );
  }
}

class JobScheduleHomePage extends StatefulWidget {
  const JobScheduleHomePage({super.key});

  @override
  State<JobScheduleHomePage> createState() => _JobScheduleHomePageState();
}

class _JobScheduleHomePageState extends State<JobScheduleHomePage> {
  final TextEditingController _codiceArticoloController = TextEditingController();
  final TextEditingController _lottoController = TextEditingController();
  final TextEditingController _numeroPezziController = TextEditingController();
  
  String _selectedPath = '';
  List<String> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('job_history') ?? [];
    });
  }

  Future<void> _saveToHistory(String entry) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, entry);
    if (_history.length > 50) {
      _history = _history.take(50).toList();
    }
    await prefs.setStringList('job_history', _history);
  }

  Future<void> _selectSaveLocation() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleziona cartella di destinazione',
    );
    
    if (selectedDirectory != null) {
      setState(() {
        _selectedPath = selectedDirectory;
      });
    }
  }

  Future<void> _generateJobFile() async {
    if (_codiceArticoloController.text.isEmpty ||
        _lottoController.text.isEmpty ||
        _numeroPezziController.text.isEmpty) {
      _showSnackBar('Inserisci tutti i campi richiesti', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String content = '${_codiceArticoloController.text}  ${_lottoController.text} ${_numeroPezziController.text}';
      final String fileName = 'Job_Schedule.txt';
      
      String finalPath;
      if (_selectedPath.isEmpty) {
        String? defaultPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Seleziona dove salvare il file',
        );
        if (defaultPath == null) return;
        finalPath = '$defaultPath/$fileName';
      } else {
        finalPath = '$_selectedPath/$fileName';
      }

      final file = File(finalPath);
      await file.writeAsString(content);

      final historyEntry = '${DateTime.now().toString().split('.')[0]} - $content';
      await _saveToHistory(historyEntry);
      setState(() {});

      _showSnackBar('File salvato con successo in: $finalPath', Colors.green);
      _clearFields();
    } catch (e) {
      _showSnackBar('Errore durante il salvataggio: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFields() {
    _codiceArticoloController.clear();
    _lottoController.clear();
    _numeroPezziController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cronologia File Generati'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _history.isEmpty
              ? const Center(child: Text('Nessun file generato ancora'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(_history[index], style: const TextStyle(fontSize: 12)),
                      dense: true,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Schedule Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: 'Cronologia',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Genera File Job Schedule',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inserisci i dati per generare il file con formato: [CODICE] [LOTTO] [PEZZI]',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _codiceArticoloController,
                      decoration: const InputDecoration(
                        labelText: 'Codice Articolo',
                        hintText: 'es. PXO7471-250905',
                        prefixIcon: Icon(Icons.inventory),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _lottoController,
                      decoration: const InputDecoration(
                        labelText: 'Lotto',
                        hintText: 'es. 310',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _numeroPezziController,
                      decoration: const InputDecoration(
                        labelText: 'Numero Pezzi',
                        hintText: 'es. 15',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Percorso di Salvataggio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPath.isEmpty 
                                ? 'Seleziona cartella (opzionale)' 
                                : _selectedPath,
                            style: TextStyle(
                              color: _selectedPath.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selectSaveLocation,
                          icon: const Icon(Icons.folder),
                          label: const Text('Scegli'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateJobFile,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Generazione...' : 'Genera File Job Schedule'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFields,
              icon: const Icon(Icons.clear),
              label: const Text('Pulisci Campi'),
            ),
            const SizedBox(height: 16),
            if (_history.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ultimo file generato:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _history.first,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codiceArticoloController.dispose();
    _lottoController.dispose();
    _numeroPezziController.dispose();
    super.dispose();
  }
}
