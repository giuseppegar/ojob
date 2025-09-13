import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class MasterArticle {
  final String id;
  final String code;
  final String description;
  final DateTime createdAt;

  MasterArticle({
    required this.id,
    required this.code,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MasterArticle.fromJson(Map<String, dynamic> json) {
    return MasterArticle(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
          tertiary: const Color(0xFF06B6D4),
          surface: const Color(0xFFF8FAFC),
          surfaceContainerHighest: const Color(0xFFFAFAFA),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E293B),
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide(color: Colors.grey.shade300),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
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
  List<MasterArticle> _masterArticles = [];
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
      _selectedPath = prefs.getString('saved_path') ?? '';
    });
    await _loadMasterArticles();
  }

  Future<void> _loadMasterArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = prefs.getStringList('master_articles') ?? [];
    setState(() {
      _masterArticles = articlesJson
          .map((jsonStr) => MasterArticle.fromJson(jsonDecode(jsonStr)))
          .toList();
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

  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_path', path);
  }

  Future<void> _clearSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_path');
    setState(() {
      _selectedPath = '';
    });
    _showSnackBar('✅ Percorso salvato rimosso', const Color(0xFF059669));
  }

  Future<void> _saveMasterArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final articlesJson = _masterArticles
        .map((article) => jsonEncode(article.toJson()))
        .toList();
    await prefs.setStringList('master_articles', articlesJson);
  }

  Future<void> _addMasterArticle(String code, String description) async {
    final article = MasterArticle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _masterArticles.add(article);
      _masterArticles.sort((a, b) => a.code.compareTo(b.code));
    });
    
    await _saveMasterArticles();
    _showSnackBar('✅ Articolo aggiunto: ${article.code}', const Color(0xFF059669));
  }

  Future<void> _updateMasterArticle(String id, String code, String description) async {
    final index = _masterArticles.indexWhere((article) => article.id == id);
    if (index != -1) {
      final updatedArticle = MasterArticle(
        id: id,
        code: code.trim(),
        description: description.trim(),
        createdAt: _masterArticles[index].createdAt,
      );
      
      setState(() {
        _masterArticles[index] = updatedArticle;
        _masterArticles.sort((a, b) => a.code.compareTo(b.code));
      });
      
      await _saveMasterArticles();
      _showSnackBar('✅ Articolo aggiornato: ${updatedArticle.code}', const Color(0xFF059669));
    }
  }

  Future<void> _deleteMasterArticle(String id) async {
    final article = _masterArticles.firstWhere((article) => article.id == id);
    setState(() {
      _masterArticles.removeWhere((article) => article.id == id);
    });
    
    await _saveMasterArticles();
    _showSnackBar('🗑️ Articolo eliminato: ${article.code}', const Color(0xFFEA580C));
  }

  void _selectMasterArticle(MasterArticle article) {
    setState(() {
      _codiceArticoloController.text = article.code;
    });
    _showSnackBar('📋 Articolo selezionato: ${article.code}', const Color(0xFF059669));
  }

  Future<void> _selectSaveLocation() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleziona cartella di destinazione',
      );
      
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        setState(() {
          _selectedPath = selectedDirectory;
        });
        await _savePath(selectedDirectory);
        _showSnackBar('✅ Percorso selezionato e salvato', const Color(0xFF059669));
      } else {
        _showSnackBar('ℹ️ Selezione annullata', const Color(0xFF64748B));
      }
    } catch (e) {
      // Fallback: usa la directory Downloads
      try {
        Directory? downloadsDir;
        
        if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
          final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
          if (homeDir != null) {
            downloadsDir = Directory('$homeDir/Downloads');
          }
        } else {
          downloadsDir = await getDownloadsDirectory();
        }
        
        if (downloadsDir != null && await downloadsDir.exists()) {
          setState(() {
            _selectedPath = downloadsDir!.path;
          });
          await _savePath(downloadsDir.path);
          _showSnackBar('✅ Cartella Downloads selezionata e salvata', const Color(0xFF059669));
        } else {
          _showSnackBar('❌ Impossibile selezionare cartella', const Color(0xFFDC2626));
        }
      } catch (fallbackError) {
        _showSnackBar('❌ Errore selezione cartella: ${e.toString()}', const Color(0xFFDC2626));
      }
    }
  }

  Future<void> _generateJobFile() async {
    // Validation
    if (_codiceArticoloController.text.trim().isEmpty ||
        _lottoController.text.trim().isEmpty ||
        _numeroPezziController.text.trim().isEmpty) {
      _showSnackBar('⚠️ Inserisci tutti i campi richiesti', const Color(0xFFEA580C));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare content
      final String codice = _codiceArticoloController.text.trim();
      final String lotto = _lottoController.text.trim();
      final String pezzi = _numeroPezziController.text.trim();
      final String content = '$codice\t$lotto\t$pezzi';
      final String fileName = 'Job_Schedule.txt';
      
      String finalPath;
      
      // Determine save location
      if (_selectedPath.isEmpty) {
        try {
          String? defaultPath = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Seleziona dove salvare il file',
          );
          
          if (defaultPath == null || defaultPath.isEmpty) {
            // Fallback: usa Downloads directory
            Directory? downloadsDir;
            
            if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
              final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
              if (homeDir != null) {
                downloadsDir = Directory('$homeDir/Downloads');
              }
            } else {
              downloadsDir = await getDownloadsDirectory();
            }
            
            if (downloadsDir != null && await downloadsDir.exists()) {
              defaultPath = downloadsDir.path;
              _showSnackBar('ℹ️ Salvato in Downloads (fallback)', const Color(0xFF059669));
            } else {
              setState(() {
                _isLoading = false;
              });
              _showSnackBar('❌ Impossibile determinare cartella di salvataggio', const Color(0xFFDC2626));
              return;
            }
          }
          finalPath = '$defaultPath/$fileName';
        } catch (e) {
          // Fallback diretto a Downloads in caso di errore
          try {
            Directory? downloadsDir;
            if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
              final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
              if (homeDir != null) {
                downloadsDir = Directory('$homeDir/Downloads');
              }
            } else {
              downloadsDir = await getDownloadsDirectory();
            }
            
            if (downloadsDir != null && await downloadsDir.exists()) {
              finalPath = '${downloadsDir.path}/$fileName';
              _showSnackBar('ℹ️ Salvato in Downloads (fallback)', const Color(0xFF059669));
            } else {
              setState(() {
                _isLoading = false;
              });
              _showSnackBar('❌ Impossibile salvare il file', const Color(0xFFDC2626));
              return;
            }
          } catch (fallbackError) {
            setState(() {
              _isLoading = false;
            });
            _showSnackBar('❌ Errore critico: impossibile salvare', const Color(0xFFDC2626));
            return;
          }
        }
      } else {
        finalPath = '$_selectedPath/$fileName';
      }
      
      // Write file
      final file = File(finalPath);
      await file.writeAsString(content, flush: true);
      
      // Verify file was written
      if (await file.exists()) {
        // Add to history
        final historyEntry = '${DateTime.now().toString().split('.')[0]} - $content';
        await _saveToHistory(historyEntry);
        setState(() {});

        _showSnackBar('✅ File "$fileName" salvato con successo!', const Color(0xFF059669));
        _clearFields();
      } else {
        throw Exception('File non trovato dopo la scrittura');
      }
      
    } catch (e) {
      _showSnackBar('❌ Errore salvataggio: ${e.toString()}', const Color(0xFFDC2626));
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
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int delay,
    TextInputType? keyboardType,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codiceArticoloController,
                  decoration: InputDecoration(
                    labelText: 'Codice Articolo',
                    hintText: 'es. PXO7471-250905',
                    prefixIcon: Icon(
                      PhosphorIcons.tag(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: PopupMenuButton<MasterArticle?>(
                  icon: Icon(
                    PhosphorIcons.package(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Articoli Master',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) {
                    if (_masterArticles.isEmpty) {
                      return [
                        PopupMenuItem<MasterArticle?>(
                          enabled: false,
                          child: Text(
                            'Nessun articolo master',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        PopupMenuItem<MasterArticle?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.plus(),
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Aggiungi primo articolo'),
                            ],
                          ),
                        ),
                      ];
                    }

                    return [
                      PopupMenuItem<MasterArticle?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.gear(),
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Gestisci articoli'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      ..._masterArticles.map((article) => PopupMenuItem<MasterArticle?>(
                        value: article,
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.package(),
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    article.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (article.description.isNotEmpty)
                                    Text(
                                      article.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ];
                  },
                  onSelected: (article) {
                    if (article == null) {
                      // Se nessun articolo è selezionato, apri la gestione
                      _showMasterArticlesDialog();
                    } else {
                      // Seleziona l'articolo
                      _selectMasterArticle(article);
                    }
                  },
                ),
              ),
            ],
          ),
          if (_masterArticles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _masterArticles.take(3).map((article) {
                return GestureDetector(
                  onTap: () => _selectMasterArticle(article),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.package(),
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.code,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      PhosphorIcons.clockCounterClockwise(),
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cronologia File',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${_history.length} file generati',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      PhosphorIcons.x(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: _history.isEmpty
                    ? Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.fileX(),
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nessun file generato ancora',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.fileText(),
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _history[index],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMasterArticlesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      PhosphorIcons.package(),
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Articoli Master',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${_masterArticles.length} articoli salvati',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddArticleDialog(),
                    icon: Icon(
                      PhosphorIcons.plus(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Aggiungi articolo',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      PhosphorIcons.x(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: _masterArticles.isEmpty
                    ? Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.package(),
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nessun articolo master ancora',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _showAddArticleDialog(),
                                icon: Icon(PhosphorIcons.plus()),
                                label: const Text('Aggiungi primo articolo'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _masterArticles.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final article = _masterArticles[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.package(),
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.code,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (article.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          article.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _selectMasterArticle(article);
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    PhosphorIcons.check(),
                                    color: Colors.green.shade600,
                                    size: 18,
                                  ),
                                  tooltip: 'Usa questo articolo',
                                ),
                                IconButton(
                                  onPressed: () => _showEditArticleDialog(article),
                                  icon: Icon(
                                    PhosphorIcons.pencil(),
                                    color: Colors.orange.shade600,
                                    size: 18,
                                  ),
                                  tooltip: 'Modifica',
                                ),
                                IconButton(
                                  onPressed: () => _confirmDeleteArticle(article),
                                  icon: Icon(
                                    PhosphorIcons.trash(),
                                    color: Colors.red.shade600,
                                    size: 18,
                                  ),
                                  tooltip: 'Elimina',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddArticleDialog() {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.plus(),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Nuovo Articolo Master'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Codice Articolo',
                hintText: 'es. PXO7471-250905',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                hintText: 'es. Flangia standard 250mm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                _addMasterArticle(
                  codeController.text.trim(),
                  descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _showEditArticleDialog(MasterArticle article) {
    final TextEditingController codeController = TextEditingController(text: article.code);
    final TextEditingController descriptionController = TextEditingController(text: article.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.pencil(),
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 12),
            const Text('Modifica Articolo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Codice Articolo',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                _updateMasterArticle(
                  article.id,
                  codeController.text.trim(),
                  descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteArticle(MasterArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.warning(),
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 12),
            const Text('Conferma Eliminazione'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Sei sicuro di voler eliminare l\'articolo '),
              TextSpan(
                text: article.code,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteMasterArticle(article.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIcons.fileText(),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Job Schedule'),
          ],
        ),
        actions: [
          FadeInRight(
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.clockCounterClockwise(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _showHistoryDialog,
                tooltip: 'Cronologia',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            PhosphorIcons.files(),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Genera File Job Schedule',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Inserisci i dati per generare il file con formato: [CODICE]→[LOTTO]→[PEZZI] (separati da TAB)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCodeField(),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _lottoController,
                      label: 'Lotto',
                      hint: 'es. 310',
                      icon: PhosphorIcons.hash(),
                      delay: 300,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _numeroPezziController,
                      label: 'Numero Pezzi',
                      hint: 'es. 15',
                      icon: PhosphorIcons.listNumbers(),
                      delay: 400,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            PhosphorIcons.folderOpen(),
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Percorso di Salvataggio',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPath.isEmpty 
                                ? PhosphorIcons.folder() 
                                : PhosphorIcons.folderSimple(),
                            color: _selectedPath.isEmpty 
                                ? Colors.grey.shade400 
                                : Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedPath.isEmpty 
                                  ? 'Seleziona cartella (opzionale)' 
                                  : _selectedPath,
                              style: TextStyle(
                                color: _selectedPath.isEmpty 
                                    ? Colors.grey.shade500 
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: _selectedPath.isEmpty 
                                    ? FontWeight.w400 
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _selectSaveLocation,
                            icon: Icon(PhosphorIcons.folderOpen()),
                            label: const Text('Scegli Cartella'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_selectedPath.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearSavedPath,
                              icon: Icon(
                                PhosphorIcons.x(),
                                size: 18,
                              ),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(color: Colors.orange.shade300),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateJobFile,
                  icon: _isLoading 
                      ? SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(PhosphorIcons.downloadSimple()),
                  label: Text(_isLoading ? 'Generazione in corso...' : 'Genera File Job Schedule'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearFields,
                  icon: Icon(PhosphorIcons.eraser()),
                  label: const Text('Pulisci Campi'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_history.isNotEmpty)
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                        Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIcons.clockCounterClockwise(),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ultimo file generato',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _history.first,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showHistoryDialog,
                        icon: Icon(
                          PhosphorIcons.arrowRight(),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        tooltip: 'Vedi cronologia completa',
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
