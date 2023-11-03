import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;

//Conexão com o banco

  final database = openDatabase(
    join(await getDatabasesPath(), 'contatos_database.db'),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE contatos(id INTEGER PRIMARY KEY, nome TEXT, telefone TEXT, email TEXT)",
      );
    },
    version: 1,
  );
  runApp(MyApp(database: database));
}

//"Classe" contato:

class Contato {
  int? id;
  String nome;
  String telefone;
  String email;

  Contato(
      {this.id,
      required this.nome,
      required this.telefone,
      required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
    };
  }

  factory Contato.fromMap(Map<String, dynamic> map) {
    return Contato(
      id: map['id'],
      nome: map['nome'],
      telefone: map['telefone'],
      email: map['email'],
    );
  }

  Contato copyWith({int? id, String? nome, String? telefone, String? email}) {
    return Contato(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
    );
  }
}

class MyApp extends StatelessWidget {
  final Future<Database> database;

  MyApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListaDeContatos(database: database),
    );
  }
}

class ListaDeContatos extends StatefulWidget {
  final Future<Database> database;

  ListaDeContatos({required this.database});

  @override
  _ListaDeContatosState createState() => _ListaDeContatosState();
}

class _ListaDeContatosState extends State<ListaDeContatos> {
  final List<Contato> Contatos = [];

  @override
  void initState() {
    super.initState();
    _ImportarContatos();
  }

  Future<void> _ImportarContatos() async {
    final Database db = await widget.database;
    final List<Map<String, dynamic>> maps = await db.query('contatos');

    setState(() {
      Contatos.clear();
      Contatos.addAll(maps.map((map) => Contato.fromMap(map)));
    });
  }

  Future<void> _addContato() async {
    await _inserirInfos(Contato(
        nome: "Novo contato",
        telefone: "(XX) 9XXXX-XXXX",
        email: "teste@teste.com"));
  }

  Future<void> _inserirInfos(Contato contato) async {
    final Database db = await widget.database;

    await db.insert(
      'contatos',
      contato.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _ImportarContatos();
  }

  Future<void> _excluirContato(Contato contato) async {
    final Database db = await widget.database;
    await db.delete('contatos');
  }

  Future<void> _editarContato(Contato contato) async {
    final contatoEditado = await showDialog<Contato>(
      context: this.context,
      builder: (BuildContext context) {
        TextEditingController nomeController =
            TextEditingController(text: contato.nome);
        TextEditingController telefoneController =
            TextEditingController(text: contato.telefone);
        TextEditingController emailController =
            TextEditingController(text: contato.email);

        return AlertDialog(
          title: Text('Editar contato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: telefoneController,
                decoration: InputDecoration(labelText: 'Fone'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nomeEditado = nomeController.text;
                  final telefoneEditado = telefoneController.text;
                  final emailEditado = emailController.text;

                  final contatoEditado = contato.copyWith(
                    nome: nomeEditado,
                    telefone: telefoneEditado,
                    email: emailEditado,
                  );

                  Navigator.of(context).pop(contatoEditado);
                },
                child: Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );

    if (contatoEditado != null) {
      await _atualizarContato(contatoEditado);
    }
  }

  Future<void> _atualizarContato(Contato contato) async {
    final Database db = await widget.database;

    await db.update(
      'contatos',
      contato.toMap(),
      where: 'id = ?',
      whereArgs: [contato.id],
    );

    _ImportarContatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        title: Text("Lista de Contatos"),
      ),
      body: ListView.builder(
        itemCount: Contatos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(Contatos[index].nome),
            subtitle: Text(
                "Telefone: ${Contatos[index].telefone}\nEmail: ${Contatos[index].email}"),
            onTap: () {
              _editarContato(Contatos[index]);
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Color.fromARGB(255, 0, 0, 0),
            onPressed: _addContato,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
