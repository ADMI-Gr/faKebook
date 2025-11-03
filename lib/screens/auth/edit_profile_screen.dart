import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import 'package:fakebook/widgets/textField_register.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _carreraCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();

  final List<String> _sedes = const [
    'ITCA FEPADE Santa Tecla',
    'ITCA FEPADE San Miguel',
    'ITCA FEPADE La Union',
    'ITCA FEPADE Santa Ana',
    'ITCA FEPADE Zacatecoluca',
  ];
  String? _selectedSede;
  final List<String> _years = const [
    '1° Primero',
    '2° Segundo',
    'Graduado',
    'Otro'
  ];
  String? _selectedYear;

  String? _displayNameError;
  String? _userError;
  String? _carreraError;
  String? _sedeError;
  String? _yearError;
  String? _bioError;

  bool _saving = false;
  File? _imageFile;
  Uint8List? _avatarBytes;
  String? _avatarPath;

  // Configuración de visibilidad
  bool _visibilityDisplayName = true;
  bool _visibilityEmail = true;
  bool _visibilityBio = true;
  bool _visibilitySede = true;
  bool _visibilityCarrera = true;
  bool _visibilityYear = true;

  //Iniciarliza los valores del formulario con la data que se recibe
  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _displayNameCtrl.text = user?.displayName ?? '';
    _bioCtrl.text = user?.bio ?? '';
    final meta = user?.metadata ?? {};
    _carreraCtrl.text = meta['carrera']?.toString() ?? '';
    _emailCtrl.text = user?.email ?? '';
    _usernameCtrl.text = user?.username ?? '';

    final sedeVal = meta['sede']?.toString();
    if (sedeVal != null && _sedes.contains(sedeVal)) {
      _selectedSede = sedeVal;
    }
    final yearVal = meta['year']?.toString();
    if (yearVal != null && _years.contains(yearVal)) {
      _selectedYear = yearVal;
    }

    // Cargar configuración de visibilidad
    _loadVisibilitySettings(meta);

    //Listeners de validacion en tiempo real, solo para los campos que son actualizables segun la tabla q me pasaron
    _displayNameCtrl.addListener(_validateDisplayName);
    _usernameCtrl.addListener(_validateUsername);
    _bioCtrl.addListener(_validateBio);
  }

  void _loadVisibilitySettings(Map<String, dynamic> meta) {
    final settings = meta['settings'];
    if (settings == null) return;

    final visibility = settings['visibility'];
    if (visibility == null) return;

    setState(() {
      _visibilityDisplayName = visibility['displayName'] ?? true;
      _visibilityEmail = visibility['email'] ?? true;
      _visibilityBio = visibility['bio'] ?? true;
      _visibilitySede = visibility['sede'] ?? true;
      _visibilityCarrera = visibility['carrera'] ?? true;
      _visibilityYear = visibility['year'] ?? true;
    });
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _carreraCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // Validaciones en tiempo real
  void _validateDisplayName() {
    setState(() {
      final value = _displayNameCtrl.text.trim();
      if (value.isEmpty) {
        _displayNameError = 'Campo obligatorio';
      } else if (value.length < 4) {
        _displayNameError = 'Mínimo 4 caracteres';
      } else {
        _displayNameError = null;
      }
    });
  }

  void _validateUsername() {
    setState(() {
      final value = _usernameCtrl.text.trim();
      if (value.isEmpty) {
        _userError = 'Campo obligatorio';
      } else if (value.length < 3) {
        _userError = 'Mínimo 3 caracteres';
      } else {
        _userError = null;
      }
    });
  }

  void _validateBio() {
    setState(() {
      final value = _bioCtrl.text.trim();
      if (value.isEmpty) {
        _bioError = 'Campo obligatorio';
      } else if (value.length < 6) {
        _bioError = 'Mínimo 6 caracteres';
      } else {
        _bioError = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _avatarPath = pickedFile.path;
      });
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final isItca = user.email.toLowerCase().endsWith('@itca.edu.sv');

    // validaciones extra por si el correo es de itca o se saltan los listener anteriores
    setState(() {
      final dn = _displayNameCtrl.text.trim();
      if (dn.isEmpty) {
        _displayNameError = 'Campo obligatorio';
      } else if (dn.length < 4) {
        _displayNameError = 'Mínimo 4 caracteres';
      } else {
        _displayNameError = null;
      }

      final uname = _usernameCtrl.text.trim();
      if (uname.isEmpty) {
        _userError = 'Campo obligatorio';
      } else if (uname.length < 3) {
        _userError = 'Mínimo 3 caracteres';
      } else {
        _userError = null;
      }

      final bio = _bioCtrl.text.trim();
      if (bio.isEmpty) {
        _bioError = 'Campo obligatorio';
      } else if (bio.length < 6) {
        _bioError = 'Mínimo 6 caracteres';
      } else {
        _bioError = null;
      }

      if (isItca) {
        _sedeError = (_selectedSede == null || _selectedSede!.trim().isEmpty)
            ? 'Selecciona una sede'
            : null;
        final carrera = _carreraCtrl.text.trim();
        _carreraError = carrera.isEmpty
            ? 'Campo obligatorio'
            : (carrera.length < 4 ? 'Mínimo 4 caracteres' : null);
        _yearError = (_selectedYear == null || _selectedYear!.trim().isEmpty)
            ? 'Selecciona un año'
            : null;
      } else {
        _sedeError = null;
        _carreraError = null;
        _yearError = null;
      }
    });

    if (_displayNameError != null ||
        _userError != null ||
        _bioError != null ||
        (isItca &&
            (_sedeError != null ||
                _carreraError != null ||
                _yearError != null))) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar actualización'),
            content: const Text(
                '¿Estás seguro de que deseas actualizar los datos de tu perfil?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      //Foto de perfil solo preparada para enviarse
      // Se obtienen los datos de la img de perfil en Bytes porque no se en q formato la guardaran
      final Uint8List? avatarBytes = _avatarBytes;
      // Se obtiene el path de la img de perfil por si se ocupa
      final String? avatarPath = _avatarPath;

      // SE CREA UNA COPIA DE METADATA PARA NO PERDER LOS DATOS PRE-ESTABLECIDOS
      final Map<String, dynamic> newMetadata = {
        ...?user.metadata,
      };

      if (isItca) {
        if (_selectedSede != null) newMetadata['sede'] = _selectedSede;
        newMetadata['carrera'] = _carreraCtrl.text.trim();
        if (_selectedYear != null) newMetadata['year'] = _selectedYear;
      } else {
        newMetadata.remove('sede');
        newMetadata.remove('carrera');
        newMetadata.remove('year');
      }

      // Guardar configuración de visibilidad
      newMetadata['settings'] = {
        ...?newMetadata['settings'],
        'visibility': {
          'displayName': _visibilityDisplayName,
          'email': _visibilityEmail,
          'bio': _visibilityBio,
          'sede': _visibilitySede,
          'carrera': _visibilityCarrera,
          'year': _visibilityYear,
        },
      };

      await ref.read(updateProfileProvider({
        'displayName': _displayNameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'avatarUrl': null,
        'metadata': newMetadata,
      }).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isItca = user.email.toLowerCase().endsWith('@itca.edu.sv');
    const primaryBlue = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'EDITAR PERFIL',
                      style: TextStyle(
                        fontSize: 26,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                        as ImageProvider<Object>
                                    : (user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                            as ImageProvider<Object>
                                        : null),
                                backgroundColor: const Color(0xFF1976D2),
                                child: (_imageFile == null &&
                                        user.avatarUrl == null)
                                    ? Text(
                                        (user.displayName?.isNotEmpty == true
                                                ? user.displayName![0]
                                                : user.username[0])
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _emailCtrl,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Correo electronico (no modificable)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFieldRegister(
                      controller: _displayNameCtrl,
                      labelText: 'Nombre',
                      errorText: _displayNameError,
                    ),
                    if (_displayNameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _displayNameError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _usernameCtrl,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario (no modificable)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    if (_userError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _userError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    TextFieldRegister(
                      controller: _bioCtrl,
                      labelText: 'Biografía',
                      errorText: _bioError,
                      maxLines: 3,
                    ),
                    if (_bioError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _bioError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ),

                    // MUESTRA LOS CAMPOS EXTRAS SI SON DE ITCA
                    if (isItca) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: false,
                        initialValue: _selectedSede ?? '',
                        decoration: InputDecoration(
                          labelText: 'Sede (no modificable)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      if (_sedeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _sedeError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _carreraCtrl,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Carrera (no modificable)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      if (_carreraError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _carreraError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedYear,
                        items: _years
                            .map((y) => DropdownMenuItem<String>(
                                  value: y,
                                  child: Text(y),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      if (_yearError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _yearError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 32),

                    // Sección de configuración de visibilidad
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          leading: const Icon(
                            Icons.visibility_outlined,
                            color: primaryBlue,
                          ),
                          title: const Text(
                            'Configuración de visibilidad',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            'Controla qué información ven otros usuarios',
                            style: TextStyle(fontSize: 12),
                          ),
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildVisibilitySwitch(
                              'Nombre',
                              'Mostrar tu nombre completo',
                              _visibilityDisplayName,
                              (value) {
                                setState(() {
                                  _visibilityDisplayName = value;
                                });
                              },
                            ),
                            _buildVisibilitySwitch(
                              'Correo electrónico',
                              'Mostrar tu correo electrónico',
                              _visibilityEmail,
                              (value) {
                                setState(() {
                                  _visibilityEmail = value;
                                });
                              },
                            ),
                            _buildVisibilitySwitch(
                              'Biografía',
                              'Mostrar tu biografía',
                              _visibilityBio,
                              (value) {
                                setState(() {
                                  _visibilityBio = value;
                                });
                              },
                            ),
                            if (isItca) ...[
                              _buildVisibilitySwitch(
                                'Sede',
                                'Mostrar tu sede ITCA',
                                _visibilitySede,
                                (value) {
                                  setState(() {
                                    _visibilitySede = value;
                                  });
                                },
                              ),
                              _buildVisibilitySwitch(
                                'Carrera',
                                'Mostrar tu carrera',
                                _visibilityCarrera,
                                (value) {
                                  setState(() {
                                    _visibilityCarrera = value;
                                  });
                                },
                              ),
                              _buildVisibilitySwitch(
                                'Año',
                                'Mostrar tu año académico',
                                _visibilityYear,
                                (value) {
                                  setState(() {
                                    _visibilityYear = value;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 18, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Los campos ocultos no se mostrarán en tu perfil público',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(
                            _saving ? 'Guardando...' : 'Guardar cambios',
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }
}
