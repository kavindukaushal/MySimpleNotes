import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'note.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomePage({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Note> _notes = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _currentSort = 'dateDesc';
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterNotes();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _databaseHelper.getSortedNotes(_currentSort);
      setState(() {
        _notes.clear();
        _notes.addAll(notes);
        _filterNotes();
      });
    } catch (e) {
      _showError('Error loading notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterNotes() {
    setState(() {
      _notes.retainWhere((note) =>
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()));
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showNoteDialog([Note? note]) async {
    final TextEditingController titleController =
    TextEditingController(text: note?.title ?? '');
    final TextEditingController contentController =
    TextEditingController(text: note?.content ?? '');
    String priority = note?.priority ?? 'Low';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(note == null ? 'Add Note' : 'Edit Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: ['High', 'Medium', 'Low'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => priority = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();

                  if (title.isEmpty || content.isEmpty) {
                    _showError('Title and content cannot be empty');
                    return;
                  }

                  final newNote = Note(
                    id: note?.id,
                    title: title,
                    content: content,
                    dateTime: DateTime.now(),
                    priority: priority,
                  );

                  if (note == null) {
                    await _databaseHelper.insertNote(newNote);
                  } else {
                    await _databaseHelper.updateNote(newNote);
                  }
                  Navigator.pop(context);
                  _loadNotes();
                },
                child: Text(note == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteNoteConfirmation(Note note) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseHelper.deleteNote(note.id!);
              Navigator.pop(context);
              _loadNotes();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sortNotes(String sortBy) {
    setState(() {
      _currentSort = sortBy;
      _loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Simple Note'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
    DropdownButton<String>(
    value: _currentSort,
    icon: const Icon(Icons.sort), // You can leave the icon color as default or customize it
    onChanged: (String? newValue) {
    if (newValue != null) {
    _sortNotes(newValue);
    }
    },
    items: [
    DropdownMenuItem(
    value: 'dateDesc',
    child: Text(
    'Sort by Date (Newest)',
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),
    ),
    ),
    DropdownMenuItem(
    value: 'dateAsc',
    child: Text(
    'Sort by Date (Oldest)',
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),
    ),
    ),
    DropdownMenuItem(
    value: 'titleAsc',
    child: Text(
    'Sort by Title (A-Z)',
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),
    ),
    ),
    DropdownMenuItem(
    value: 'titleDesc',
    child: Text(
    'Sort by Title (Z-A)',
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),
    ),
    ),
    DropdownMenuItem(
    value: 'priority',
    child: Text(
    'Sort by Priority',
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),
    ),
    ),
    ],
    style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    ),


    ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                ? const Center(child: Text('No notes found'))
                : _isGridView
                ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return _buildNoteCard(note);
              },
            )
                : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return _buildNoteCard(note);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final dateFormatted = DateFormat.yMMMd().add_jm().format(note.dateTime);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(note.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              dateFormatted,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              'Priority: ${note.priority}',
              style: TextStyle(
                color: note.priority == 'High'
                    ? Colors.red
                    : note.priority == 'Medium'
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteNoteConfirmation(note),
        ),
        onTap: () => _showNoteDialog(note),
      ),
    );
  }
}
