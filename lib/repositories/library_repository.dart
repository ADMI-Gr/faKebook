import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class LibraryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== CATÁLOGO DE BIBLIOTECA ====================

  /// Obtener todos los libros del catálogo
  Future<List<BookModel>> getAllBooks() async {
    final response =
        await _supabase.from('books').select().order('title', ascending: true);

    return (response as List).map((book) => BookModel.fromMap(book)).toList();
  }

  /// Buscar libros por título o autor (búsqueda simple)
  Future<List<BookModel>> searchBooks(String query) async {
    // Limpiar la query: trim y normalizar espacios
    final cleanQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleanQuery.isEmpty) return [];

    final response = await _supabase
        .from('books')
        .select()
        .or('title.ilike.%$cleanQuery%,author.ilike.%$cleanQuery%')
        .order('title', ascending: true);

    return (response as List).map((book) => BookModel.fromMap(book)).toList();
  }

  /// Buscar libro por ISBN (código de barras)
  Future<BookModel?> searchBookByISBN(String isbn) async {
    // Limpiar el ISBN (quitar guiones, espacios, etc.)
    final cleanISBN = isbn.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanISBN.isEmpty) return null;

    final response = await _supabase
        .from('books')
        .select()
        .eq('isbn', cleanISBN)
        .maybeSingle();

    if (response == null) return null;
    return BookModel.fromMap(response);
  }

  /// Buscar libros por título, autor o ISBN (búsqueda avanzada)
  Future<List<BookModel>> searchBooksAdvanced(String query) async {
    // Limpiar la query
    final cleanQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleanQuery.isEmpty) return [];

    // Extraer solo números para verificar si es ISBN
    final cleanISBN = query.replaceAll(RegExp(r'[^\d]'), '');

    // Si parece un ISBN (10 o 13 dígitos), buscar por ISBN primero
    if (cleanISBN.length == 10 || cleanISBN.length == 13) {
      try {
        final isbnResult = await searchBookByISBN(cleanISBN);
        if (isbnResult != null) {
          return [isbnResult];
        }
      } catch (e) {
        print('Error buscando por ISBN: $e');
      }
    }

    // Si no es ISBN o no se encontró, buscar por título/autor
    // Usar búsqueda OR con ilike (case-insensitive)
    try {
      final response = await _supabase
          .from('books')
          .select()
          .or('title.ilike.%$cleanQuery%,author.ilike.%$cleanQuery%')
          .order('title', ascending: true);

      return (response as List).map((book) => BookModel.fromMap(book)).toList();
    } catch (e) {
      print('Error en búsqueda avanzada: $e');
      // Si falla, intentar búsqueda palabra por palabra
      return await _searchByWords(cleanQuery);
    }
  }

  /// Búsqueda alternativa por palabras individuales
  Future<List<BookModel>> _searchByWords(String query) async {
    final words = query.split(' ').where((w) => w.length > 2).toList();

    if (words.isEmpty) return [];

    // Construir condición OR para cada palabra
    final conditions = words
        .map((word) => 'title.ilike.%$word%,author.ilike.%$word%')
        .join(',');

    try {
      final response = await _supabase
          .from('books')
          .select()
          .or(conditions)
          .order('title', ascending: true);

      return (response as List).map((book) => BookModel.fromMap(book)).toList();
    } catch (e) {
      print('Error en búsqueda por palabras: $e');
      return [];
    }
  }

  /// Obtener solo libros disponibles
  Future<List<BookModel>> getAvailableBooks() async {
    final response = await _supabase
        .from('books')
        .select()
        .gt('available_copies', 0)
        .order('title', ascending: true);

    return (response as List).map((book) => BookModel.fromMap(book)).toList();
  }

  /// Obtener un libro por ID
  Future<BookModel?> getBookById(String bookId) async {
    final response =
        await _supabase.from('books').select().eq('id', bookId).maybeSingle();

    if (response == null) return null;
    return BookModel.fromMap(response);
  }

  // ==================== RENTAR LIBRO ====================

  /// Rentar un libro
  Future<BookRentalModel> rentBook(String userId, String bookId) async {
    // 1. Verificar que el libro esté disponible
    final book = await getBookById(bookId);
    if (book == null) {
      throw Exception('Libro no encontrado');
    }
    if (!book.isAvailable) {
      throw Exception('No hay copias disponibles');
    }

    // 2. Verificar que el usuario no tenga ya este libro rentado
    final existingRental = await _supabase
        .from('book_rentals')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .eq('status', 'active')
        .maybeSingle();

    if (existingRental != null) {
      throw Exception('Ya tienes este libro rentado');
    }

    // 3. Calcular fecha de vencimiento
    final now = DateTime.now();
    final dueDate = now.add(Duration(days: book.rentalDurationDays));

    // 4. Crear la renta
    final rentalData = {
      'user_id': userId,
      'book_id': bookId,
      'rented_at': now.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': 'active',
      'extensions_count': 0,
    };

    final rentalResponse = await _supabase
        .from('book_rentals')
        .insert(rentalData)
        .select()
        .single();

    // 5. Decrementar copias disponibles
    await _supabase
        .rpc('decrement_available_copies', params: {'book_id': bookId});

    return BookRentalModel.fromMap(rentalResponse);
  }

  // ==================== DEVOLVER LIBRO ====================

  /// Devolver un libro
  Future<void> returnBook(String rentalId) async {
    final rental = await _supabase
        .from('book_rentals')
        .select('*, books(*)')
        .eq('id', rentalId)
        .single();

    if (rental['status'] != 'active') {
      throw Exception('Esta renta ya fue procesada');
    }

    // 1. Actualizar la renta
    await _supabase.from('book_rentals').update({
      'returned_at': DateTime.now().toIso8601String(),
      'status': 'returned',
    }).eq('id', rentalId);

    // 2. Incrementar copias disponibles
    final bookId = rental['book_id'];
    await _supabase
        .rpc('increment_available_copies', params: {'book_id': bookId});
  }

  // ==================== EXTENDER RENTA ====================

  /// Extender el tiempo de renta (máximo 2 veces)
  Future<BookRentalModel> extendRental(String rentalId,
      {int extensionDays = 7}) async {
    final rental = await _supabase
        .from('book_rentals')
        .select('*, books(*)')
        .eq('id', rentalId)
        .single();

    final currentRental = BookRentalModel.fromMap(rental);

    if (!currentRental.canExtend) {
      throw Exception('No se puede extender más esta renta');
    }

    // Extender fecha de vencimiento
    final newDueDate = currentRental.dueDate.add(Duration(days: extensionDays));
    final newExtensionsCount = currentRental.extensionsCount + 1;

    final updated = await _supabase
        .from('book_rentals')
        .update({
          'due_date': newDueDate.toIso8601String(),
          'extensions_count': newExtensionsCount,
        })
        .eq('id', rentalId)
        .select()
        .single();

    return BookRentalModel.fromMap(updated);
  }

  // ==================== HISTORIAL DE RENTAS ====================

  /// Obtener rentas activas del usuario
  Future<List<BookRentalModel>> getActiveRentals(String userId) async {
    final response = await _supabase
        .from('book_rentals')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('due_date', ascending: true);

    return (response as List)
        .map((rental) => BookRentalModel.fromMap(rental))
        .toList();
  }

  /// Obtener historial completo de rentas
  Future<List<BookRentalModel>> getRentalHistory(String userId) async {
    final response = await _supabase
        .from('book_rentals')
        .select('*, books(*)')
        .eq('user_id', userId)
        .order('rented_at', ascending: false);

    return (response as List)
        .map((rental) => BookRentalModel.fromMap(rental))
        .toList();
  }

  // ==================== SOLICITUDES DE LIBROS ====================

  /// Solicitar un nuevo libro
  Future<BookRequestModel> requestBook({
    required String userId,
    required String openLibraryId,
    required String title,
    String? author,
  }) async {
    // Verificar que no exista una solicitud pendiente para el mismo libro
    final existingRequest = await _supabase
        .from('book_requests')
        .select()
        .eq('user_id', userId)
        .eq('open_library_id', openLibraryId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existingRequest != null) {
      throw Exception('Ya existe una solicitud pendiente para este libro');
    }

    final requestData = {
      'user_id': userId,
      'open_library_id': openLibraryId,
      'title': title,
      'author': author,
      'status': 'pending',
      'requested_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('book_requests')
        .insert(requestData)
        .select()
        .single();

    return BookRequestModel.fromMap(response);
  }

  /// Obtener solicitudes del usuario
  Future<List<BookRequestModel>> getUserRequests(String userId) async {
    final response = await _supabase
        .from('book_requests')
        .select()
        .eq('user_id', userId)
        .order('requested_at', ascending: false);

    return (response as List)
        .map((request) => BookRequestModel.fromMap(request))
        .toList();
  }

  // ==================== OPEN LIBRARY API ====================

  /// Buscar libros en Open Library API por query
  Future<List<OpenLibraryBook>> searchOpenLibrary(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final url = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(cleanQuery)}&limit=20');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error al buscar en Open Library');
    }

    final data = json.decode(response.body);
    final docs = data['docs'] as List;

    return docs.map((doc) => OpenLibraryBook.fromJson(doc)).toList();
  }

  /// Buscar libro en Open Library por ISBN
  Future<List<OpenLibraryBook>> searchOpenLibraryByISBN(String isbn) async {
    // Limpiar el ISBN
    final cleanISBN = isbn.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanISBN.isEmpty) return [];

    final url = Uri.parse(
        'https://openlibrary.org/search.json?isbn=$cleanISBN&limit=5');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Error al buscar en Open Library');
    }

    final data = json.decode(response.body);
    final docs = data['docs'] as List;

    return docs.map((doc) => OpenLibraryBook.fromJson(doc)).toList();
  }

  /// Buscar en Open Library (inteligente: detecta ISBN automáticamente)
  Future<List<OpenLibraryBook>> searchOpenLibraryAdvanced(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Limpiar y verificar si es un ISBN
    final cleanISBN = query.replaceAll(RegExp(r'[^\d]'), '');

    // Si parece un ISBN (10 o 13 dígitos), buscar por ISBN
    if (cleanISBN.length == 10 || cleanISBN.length == 13) {
      try {
        final results = await searchOpenLibraryByISBN(cleanISBN);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (e) {
        // Si falla la búsqueda por ISBN, continuar con búsqueda normal
      }
    }

    // Búsqueda normal por título/autor
    return await searchOpenLibrary(cleanQuery);
  }

  /// Obtener detalles de un libro de Open Library
  Future<OpenLibraryBook?> getOpenLibraryBookDetails(
      String openLibraryId) async {
    final url = Uri.parse('https://openlibrary.org$openLibraryId.json');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body);
    return OpenLibraryBook.fromJson(data);
  }
}
