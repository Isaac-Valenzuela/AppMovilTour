import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'login_page.dart';

class TurismoPage extends StatefulWidget {
  const TurismoPage({super.key});

  @override
  State<TurismoPage> createState() => _TurismoPageState();
}

class _TurismoPageState extends State<TurismoPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();
  final TextEditingController _autorController = TextEditingController();

  final List<File> _imagenesSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();
  bool _subiendoImagen = false;

  Future<void> _seleccionarImagenes() async {
    final List<XFile>? imagenes = await _picker.pickMultiImage();
    if (imagenes != null && imagenes.isNotEmpty) {
      setState(() {
        _imagenesSeleccionadas.clear();
        _imagenesSeleccionadas.addAll(imagenes.take(15).map((x) => File(x.path)));
      });
    }
  }

  Future<void> _tomarFoto() async {
    if (_imagenesSeleccionadas.length >= 15) return;
    final XFile? imagen = await _picker.pickImage(source: ImageSource.camera);
    if (imagen != null) {
      setState(() {
        if (_imagenesSeleccionadas.length < 15) {
          _imagenesSeleccionadas.add(File(imagen.path));
        }
      });
    }
  }

  Future<List<String>> _subirImagenesASupabase(List<File> imagenes) async {
    List<String> urls = [];
    setState(() {
      _subiendoImagen = true;
    });
    try {
      for (final imagen in imagenes) {
        final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imagen.path)}';
        final storageResponse = await supabase.storage
            .from('fotosturismo')
            .upload(nombreArchivo, imagen);

        if (storageResponse.isNotEmpty) {
          final url = supabase.storage.from('fotosturismo').getPublicUrl(nombreArchivo);
          urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      return [];
    } finally {
      setState(() {
        _subiendoImagen = false;
      });
    }
  }

  void _mostrarModalPublicar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Row(
                        children: [
                          Icon(
                            Icons.add_location_alt,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nuevo sitio turístico',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Form fields
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del lugar',
                          hintText: 'Ej: Playa de Los Ingleses',
                          prefixIcon: const Icon(Icons.place_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingrese el nombre del lugar' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe este lugar turístico...',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingrese una descripción' : null,
                      ),
                      const SizedBox(height: 16),
                      // Image selection section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_camera,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fotos (mínimo 5, máximo 15)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await _seleccionarImagenes();
                                      setModalState(() {});
                                    },
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('Galería'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _imagenesSeleccionadas.length >= 15 
                                          ? null 
                                          : () async {
                                              await _tomarFoto();
                                              setModalState(() {});
                                            },
                                      icon: const Icon(Icons.camera_alt_outlined),
                                      label: const Text('Cámara'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_imagenesSeleccionadas.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    '${_imagenesSeleccionadas.length} imagen(es) seleccionada(s)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _imagenesSeleccionadas.length >= 5 
                                          ? Colors.green[100] 
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _imagenesSeleccionadas.length >= 5 
                                          ? '✓ Mínimo alcanzado' 
                                          : 'Faltan ${5 - _imagenesSeleccionadas.length} fotos',
                                      style: TextStyle(
                                        color: _imagenesSeleccionadas.length >= 5 
                                            ? Colors.green[700] 
                                            : Colors.orange[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _imagenesSeleccionadas.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              _imagenesSeleccionadas[index],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  _imagenesSeleccionadas.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_subiendoImagen) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Subiendo imágenes...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudController,
                              decoration: InputDecoration(
                                labelText: 'Latitud',
                                hintText: 'Ej: -34.9011',
                                prefixIcon: const Icon(Icons.my_location),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) =>
                                  value == null || double.tryParse(value) == null
                                      ? 'Latitud inválida'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudController,
                              decoration: InputDecoration(
                                labelText: 'Longitud',
                                hintText: 'Ej: -58.3775',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) =>
                                  value == null || double.tryParse(value) == null
                                      ? 'Longitud inválida'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _autorController,
                        decoration: InputDecoration(
                          labelText: 'Autor',
                          hintText: 'Tu nombre',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingrese el nombre del autor' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: (_subiendoImagen || _imagenesSeleccionadas.length < 5) ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    await _agregarEntrada();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sitio turístico publicado exitosamente'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al publicar: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: _subiendoImagen
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.publish),
                              label: Text(
                                _subiendoImagen 
                                    ? 'Publicando...' 
                                    : _imagenesSeleccionadas.length < 5
                                        ? 'Agrega más fotos (${5 - _imagenesSeleccionadas.length} faltan)'
                                        : 'Publicar',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _horaMinutos(String isoString) {
    final fecha = DateTime.parse(isoString).toLocal();
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _cargarEntradas() async {
    final response = await supabase
        .from('turismo')
        .select()
        .order('fecha', ascending: false);

    return response;
  }

  Future<void> _agregarEntrada() async {
    if (_formKey.currentState!.validate()) {
      // Validar que tenga al menos 5 fotos
      if (_imagenesSeleccionadas.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes agregar al menos 5 fotos para publicar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<String> fotosUrls = [];
      if (_imagenesSeleccionadas.isNotEmpty) {
        fotosUrls = await _subirImagenesASupabase(_imagenesSeleccionadas);
        if (fotosUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir las imágenes')),
          );
          return;
        }
      }

      await supabase.from('turismo').insert({
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fotos': fotosUrls, // Guardar como arreglo de URLs
        'latitud': double.parse(_latitudController.text),
        'longitud': double.parse(_longitudController.text),
        'autor': _autorController.text.trim(),
        'fecha': DateTime.now().toIso8601String(),
      });

      _nombreController.clear();
      _descripcionController.clear();
      _latitudController.clear();
      _longitudController.clear();
      _autorController.clear();
      setState(() {
        _imagenesSeleccionadas.clear();
      });
      FocusScope.of(context).unfocus();

      setState(() {}); // Actualiza la lista
    }
  }

  Future<List<Map<String, dynamic>>> _cargarResenas(int sitioId) async {
    final response = await supabase
        .from('resenas')
        .select('comentario, fecha, usuario_id')
        .eq('sitio_id', sitioId)
        .order('fecha', ascending: false);
    return response;
  }

  Future<void> _agregarResena(int sitioId, String comentario) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('resenas').insert({
      'sitio_id': sitioId,
      'usuario_id': userId,
      'comentario': comentario,
    });
  }

  void _mostrarDialogoResenas(BuildContext context, Map<String, dynamic> sitio) async {
    final TextEditingController comentarioController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.rate_review,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reseñas de "${sitio['nombre']}"',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Información de ubicación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ubicación: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${sitio['latitud']?.toStringAsFixed(4) ?? '0.0000'}, ${sitio['longitud']?.toStringAsFixed(4) ?? '0.0000'}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cargarResenas(sitio['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar reseñas',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    );
                  }
                  final resenas = snapshot.data ?? [];
                  if (resenas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_outlined, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Sin reseñas aún',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemCount: resenas.length,
                      itemBuilder: (context, index) {
                        final resena = resenas[index];
                        final fecha = DateTime.parse(resena['fecha']).toLocal();
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resena['comentario'],
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${fecha.day}/${fecha.month}/${fecha.year} a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Agregar reseña',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioController,
                decoration: InputDecoration(
                  hintText: 'Escribe tu reseña sobre este lugar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (comentarioController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor escribe una reseña'),
                        ),
                      );
                      return;
                    }
                    try {
                      await _agregarResena(sitio['id'], comentarioController.text.trim());
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reseña agregada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar reseña: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Publicar reseña',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_location, size: 24),
            SizedBox(width: 8),
            Text('Blog de Turismo'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true) {
                  await supabase.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sitios publicados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cargarEntradas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando sitios...'),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar sitios',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay sitios publicados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega el primer sitio turístico usando el formulario',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final data = entries[index];
                    final hora = _horaMinutos(data['fecha']);
                    final fotos = data['fotos'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image section
                          if (fotos.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                child: fotos.length == 1
                                    ? Image.network(
                                        fotos[0],
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Error al cargar imagen',
                                                    style: TextStyle(color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Stack(
                                        children: [
                                          Image.network(
                                            fotos[0],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 200,
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.photo_library,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '+${fotos.length - 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          // Content section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['nombre'] ?? 'Sin nombre',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hora,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['descripcion'] ?? 'Sin descripción',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Por ${data['autor'] ?? 'Anónimo'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['latitud']?.toStringAsFixed(4) ?? '0'}, ${data['longitud']?.toStringAsFixed(4) ?? '0'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),                                  ),
                                ],
                              ),
                              if (fotos.length > 1) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: Colors.black,
                                              child: Container(
                                                height: 400,
                                                child: Column(
                                                  children: [
                                                    AppBar(
                                                      title: Text('${fotos.length} fotos'),
                                                      backgroundColor: Colors.transparent,
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                    ),
                                                    Expanded(
                                                      child: PageView.builder(
                                                        itemCount: fotos.length,
                                                        itemBuilder: (context, index) {
                                                          return Container(
                                                            margin: const EdgeInsets.all(8),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: Image.network(
                                                                fotos[index],
                                                                fit: BoxFit.contain,
                                                              ),
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
                                        },
                                        icon: const Icon(Icons.photo_library_outlined),
                                        label: Text('Ver ${fotos.length} fotos'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _mostrarDialogoResenas(context, data),
                                        icon: const Icon(Icons.rate_review_outlined),
                                        label: const Text('Reseñas'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _mostrarDialogoResenas(context, data),
                                    icon: const Icon(Icons.rate_review_outlined),
                                    label: const Text('Ver reseñas'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalPublicar,
        icon: const Icon(Icons.add_location_alt),
        label: const Text(
          'Publicar sitio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}