import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';
import '../models/usuario.dart';
import '../widgets/banner_delete.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';

class GestionUsuarioPage extends StatefulWidget {
  const GestionUsuarioPage({super.key});

  @override
  State<GestionUsuarioPage> createState() => _GestionUsuarioState();
}

class _GestionUsuarioState extends State<GestionUsuarioPage> with UserLoaderMixin{
  UserType _rolSelect = UserType.todos;

  List <Usuario> _allUser = [];
  List <Usuario> _allJefes = [];
  List <Usuario> _allAdministrativos = [];
  List <Usuario> _allClientes = [];
  List <Usuario> _allTrabajadores = [];
  List <Usuario> _foundUser = [];

  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _changeList (UserType rol){
    switch(rol){
      case UserType.jefe:
        if(_allJefes.isEmpty){

          _allJefes = _allUser.where((user)=>UserType.values.byName(user.rol!)==rol).toList();
        }
        _foundUser = _allJefes;
        break;

      case UserType.administrativo:
        if(_allAdministrativos.isEmpty){
          _allAdministrativos = _allUser.where((user)=>UserType.values.byName(user.rol!)==rol).toList();
        }
        _foundUser = _allAdministrativos;
        break;

      case UserType.trabajador:
        if(_allTrabajadores.isEmpty){
          _allTrabajadores = _allUser.where((user)=>UserType.values.byName(user.rol!)==rol).toList();
        }
        _foundUser = _allTrabajadores;
        break;
      case UserType.cliente:
        if(_allClientes.isEmpty){
          _allClientes = _allUser.where((user)=>UserType.values.byName(user.rol!)==rol).toList();
        }
        _foundUser = _allClientes;
        break;
      case UserType.todos:
        _foundUser = _allUser;
        break;
    }
  }
  void _searchUser(String enteredKeyword) {
    List<Usuario> results = [];

    _changeList(_rolSelect);
    results = _foundUser;

    if (enteredKeyword.isNotEmpty) {
      results =
          _foundUser.where((user) {
            final searchLower = enteredKeyword.toLowerCase().trim();

            final firstName = (user.firstName ?? '').toLowerCase();
            final lastName = (user.lastName ?? '').toLowerCase();

            final nameCompleted = "$firstName $lastName";
            nameCompleted.trim();
            return firstName.contains(searchLower) ||
                lastName.contains(searchLower) ||
                nameCompleted.contains(searchLower);
          }).toList();
    }

    setState(() {
      _foundUser = results;
    });
  }

  Future<void> _deleteMe() async {
    debugPrint("ID: $userId");
    _allUser.removeWhere((user) {
      return user.id == userId;
    });
  }

  Future<void> _loadData() async {
    await loadCurrentUserData();
    if(userName == null){
      return;
    }
    try {

      _allUser = await _userRepository.getUsers();

      if (mounted) {
        setState(() {

          _deleteMe();
          _foundUser = _allUser;
        });
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
  }

  Future<void> _deleteUser(int id) async{

    try{
      final res = await _userRepository.delete(id);
      if (mounted){
        ToastManager.show(context, res, success: true);
        _loadData();

      }
    }catch(e){
      if (mounted) ToastManager.show(context, "$e", success: false);
    }
  }
  @override
  Widget build(BuildContext context){

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }


    return Scaffold(
        drawer: MenuEmpresa(current: PageKind.usuarios, rol: userRol!),
        body: LayoutBuilder(
            builder: (context, constraints) {
              bool esMovil = constraints.maxWidth < 700;

              double cardWidth = (constraints.maxWidth - 80 - 10) / 2;

              if(esMovil){
                cardWidth = constraints.maxWidth;
              }

              if(!isLoadingUser && userRol != UserType.jefe){
                return const NoAccessWidget();
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                    padding: esMovil
                        ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                        : EdgeInsets.all(40),
                  child:Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      if (Scaffold.of(context).isDrawerOpen) {
                                        Navigator.pop(context);
                                      } else {
                                        Scaffold.of(context).openDrawer();
                                      }
                                    },
                                    icon: Icon(Icons.menu, color: Color(0xFF222B6F))
                                ),
                                Spacer(),
                                Text(
                                  'GESTIÓN DE USUARIOS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: esMovil ? 20 : 24,
                                    color: Color(0xFF222B6F),
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                            SizedBox(height: 40,),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(

                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 15,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: esMovil ? constraints.maxWidth : 500,
                                    child:  SegmentedButton<UserType>(
                                      selected: {_rolSelect},
                                      showSelectedIcon: false,
                                      onSelectionChanged: (Set<UserType> newType,) {
                                        setState(() {
                                          _rolSelect = newType.first;
                                          _changeList(_rolSelect);
                                        });
                                      },

                                      style: SegmentedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        alignment: Alignment.center,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                            10.0,
                                          ),
                                          side: BorderSide.none,
                                        ),
                                        side: BorderSide(
                                          color:
                                          Color(0xFF222B6F),
                                          width: 2.0,
                                        ),
                                      ),
                                      segments: <ButtonSegment<UserType>>[
                                        ButtonSegment<UserType>(
                                          value: UserType.jefe,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Jefe',
                                              style: TextStyle(
                                                color: Color(0xFF222B6F),
                                              ),
                                            ),
                                          ),
                                        ),
                                        ButtonSegment<UserType>(
                                          value: UserType.administrativo,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              esMovil ? 'Admin' : 'Administrativo',
                                              style: TextStyle(color: Color(0xFF222B6F),),
                                            ),
                                          ),
                                        ),
                                        ButtonSegment<UserType>(
                                          value: UserType.trabajador,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Trabajador',
                                              style: TextStyle(color: Color(0xFF222B6F),),),

                                          ),
                                        ),

                                        ButtonSegment<UserType>(
                                          value: UserType.cliente,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text('Cliente', style: TextStyle(color: Color(0xFF222B6F), ),),
                                          ),
                                        ),

                                        ButtonSegment<UserType>(
                                          value: UserType.todos,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text('Todos', style: TextStyle(color: Color(0xFF222B6F),),),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: esMovil ? constraints.maxWidth : 300,
                                    child: Row(
                                      children: [
                                        Expanded(child: Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: TextField(
                                            onChanged: (value) => _searchUser(value),
                                            decoration: InputDecoration(
                                              prefixIcon: Icon(
                                                Icons.search,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                              hintText: 'Buscar usuario ...',
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 10,
                                              ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),),
                                        IconButton(
                                          tooltip: 'Crear usuario',
                                          iconSize: 30.0,
                                          icon: const Icon(Icons.add, color: Color(0xFF222B6F)),

                                          onPressed: () async {
                                            await Navigator.pushNamed(context, 'createUser/');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            SizedBox(height: 40,),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.start,
                              children: _foundUser.map((user) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: Card(
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text("${user.firstName} ${user.lastName}"),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Modificar Usario',
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F)),
                                            onPressed: () {Navigator.pushNamed(context, 'modificateUser/', arguments: user.id);},
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                                            onPressed: () {
                                              mostrarDialogoConfirmacion(
                                                context: context,
                                                mensaje: "¿Estas seguro que quieres borrar a este usuario?",
                                                id: user.id!,
                                                accionBorrar: (idParaBorrar) async {
                                                  await _deleteUser(idParaBorrar);
                                                },
                                              );
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        )
                    ),
              );
          }),
    );
  }
}