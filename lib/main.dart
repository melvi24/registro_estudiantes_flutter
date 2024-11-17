import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Student {
  final int? id;
  final String name;
  final String email;
  final int age;
  final String address; // Nuevo campo

  Student({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.address, // Agregado al constructor
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      age: json['age'],
      address: json['address'], // Agregado al fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'address': address, // Agregado al toJson
    };
  }
}

class StudentService {
  final String baseUrl = 'http://localhost:8000';

  Future<List<Student>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  Future<void> createStudent(Student student) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(student.toJson()),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        var errorData = json.decode(response.body);
        if (errorData['detail'] == 'Email already exists') {
          throw Exception('El email ya está registrado');
        }
        throw Exception(errorData['detail'] ?? 'Error desconocido');
      }
    } catch (e) {
      throw Exception(e.toString().contains('Exception:') ?
      e.toString().split('Exception: ')[1] : 'Error de red: $e');
    }
  }

  Future<void> updateStudent(int id, Student student) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(student.toJson()),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        var errorData = json.decode(response.body);
        if (errorData['detail'] == 'Email already exists') {
          throw Exception('El email ya está registrado');
        }
        throw Exception(errorData['detail'] ?? 'Error desconocido');
      }
    } catch (e) {
      throw Exception(e.toString().contains('Exception:') ?
      e.toString().split('Exception: ')[1] : 'Error de red: $e');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/students/$id'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar estudiante');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Estudiantes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StudentService _studentService = StudentService();
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController(); // Nuevo controller
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _students = await _studentService.getStudents();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStudentDialog({Student? student}) {
    final bool isEditing = student != null;

    if (isEditing) {
      _nameController.text = student.name;
      _emailController.text = student.email;
      _ageController.text = student.age.toString();
      _addressController.text = student.address; // Agregado
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Editar Estudiante' : 'Agregar Estudiante',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Este campo es requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Edad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Este campo es requerido';
                    if (int.tryParse(value!) == null) return 'Debe ser un número';
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField( // Nuevo campo de dirección
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2, // Permitir múltiples líneas para direcciones largas
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _submitForm(student?.id),
                      child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(int? id) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final student = Student(
          name: _nameController.text,
          email: _emailController.text,
          age: int.parse(_ageController.text),
          address: _addressController.text, // Agregado
        );

        if (id != null) {
          await _studentService.updateStudent(id, student);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estudiante actualizado exitosamente')),
          );
        } else {
          await _studentService.createStudent(student);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estudiante agregado exitosamente')),
          );
        }

        Navigator.pop(context);
        _loadStudents();
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _studentService.deleteStudent(student.id!);
                _loadStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estudiante eliminado exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _ageController.clear();
    _addressController.clear(); // Agregado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estudiantes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error de conexión',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudents,
              child: Text('Reintentar'),
            ),
          ],
        ),
      )
          : _students.isEmpty
          ? Center(
        child: Text('No hay estudiantes registrados'),
      )
          : RefreshIndicator(
        onRefresh: _loadStudents,
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            return Dismissible(
              key: Key(student.id.toString()),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                _showDeleteConfirmation(student);
                return false;
              },
              child: Card(
                margin: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: ListTile(
                  title: Text(student.name),
                  subtitle: Text(
                    'Email: ${student.email}\nEdad: ${student.age}\nDirección: ${student.address}', // Actualizado
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showStudentDialog(student: student),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose(); // Agregado
    super.dispose();
  }
}

void main() {
  runApp(MyApp());
}