import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/library_repository.dart';
import '../models/book_model.dart';

// ==================== REPOSITORY PROVIDER ====================

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

// ==================== CATÁLOGO DE LIBROS ====================

/// Provider para obtener todos los libros del catálogo
final allBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getAllBooks();
});

/// Provider para obtener solo libros disponibles
final availableBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getAvailableBooks();
});

/// Provider para buscar libros (con parámetro) - búsqueda simple
final searchBooksProvider =
    FutureProvider.family<List<BookModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchBooks(query);
});

/// Provider para búsqueda avanzada (incluye ISBN)
final searchBooksAdvancedProvider =
    FutureProvider.family<List<BookModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchBooksAdvanced(query);
});

/// Provider para buscar libro por ISBN específico
final searchBookByISBNProvider =
    FutureProvider.family<BookModel?, String>((ref, isbn) async {
  if (isbn.isEmpty) return null;
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchBookByISBN(isbn);
});

/// Provider para obtener un libro específico
final bookByIdProvider =
    FutureProvider.family<BookModel?, String>((ref, bookId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getBookById(bookId);
});

// ==================== RENTAS DEL USUARIO ====================

/// Provider para obtener rentas activas del usuario
final activeRentalsProvider =
    FutureProvider.family<List<BookRentalModel>, String>((ref, userId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getActiveRentals(userId);
});

/// Provider para obtener historial completo de rentas
final rentalHistoryProvider =
    FutureProvider.family<List<BookRentalModel>, String>((ref, userId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getRentalHistory(userId);
});

/// Provider para rentar un libro
final rentBookProvider =
    FutureProvider.family<BookRentalModel, Map<String, String>>(
        (ref, params) async {
  final repo = ref.read(libraryRepositoryProvider);
  final userId = params['userId']!;
  final bookId = params['bookId']!;

  final rental = await repo.rentBook(userId, bookId);

  // Invalidar providers relevantes para refrescar la UI
  ref.invalidate(activeRentalsProvider(userId));
  ref.invalidate(allBooksProvider);
  ref.invalidate(availableBooksProvider);
  ref.invalidate(bookByIdProvider(bookId));

  return rental;
});

/// Provider para devolver un libro
final returnBookProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final repo = ref.read(libraryRepositoryProvider);
  final rentalId = params['rentalId']!;
  final userId = params['userId']!;

  await repo.returnBook(rentalId);

  // Invalidar providers relevantes
  ref.invalidate(activeRentalsProvider(userId));
  ref.invalidate(rentalHistoryProvider(userId));
  ref.invalidate(allBooksProvider);
  ref.invalidate(availableBooksProvider);
});

/// Provider para extender una renta
final extendRentalProvider =
    FutureProvider.family<BookRentalModel, Map<String, dynamic>>(
        (ref, params) async {
  final repo = ref.read(libraryRepositoryProvider);
  final rentalId = params['rentalId'] as String;
  final userId = params['userId'] as String;
  final extensionDays = params['extensionDays'] as int? ?? 7;

  final updatedRental =
      await repo.extendRental(rentalId, extensionDays: extensionDays);

  // Invalidar providers relevantes
  ref.invalidate(activeRentalsProvider(userId));

  return updatedRental;
});

// ==================== SOLICITUDES DE LIBROS ====================

/// Provider para obtener solicitudes del usuario
final userRequestsProvider =
    FutureProvider.family<List<BookRequestModel>, String>((ref, userId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getUserRequests(userId);
});

/// Provider para solicitar un libro
final requestBookProvider =
    FutureProvider.family<BookRequestModel, Map<String, String?>>(
        (ref, params) async {
  final repo = ref.read(libraryRepositoryProvider);
  final userId = params['userId']!;
  final openLibraryId = params['openLibraryId']!;
  final title = params['title']!;
  final author = params['author'];

  final request = await repo.requestBook(
    userId: userId,
    openLibraryId: openLibraryId,
    title: title,
    author: author,
  );

  // Invalidar solicitudes del usuario
  ref.invalidate(userRequestsProvider(userId));

  return request;
});

// ==================== OPEN LIBRARY API ====================

/// Provider para buscar libros en Open Library (búsqueda simple)
final searchOpenLibraryProvider =
    FutureProvider.family<List<OpenLibraryBook>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchOpenLibrary(query);
});

/// Provider para búsqueda avanzada en Open Library (detecta ISBN)
final searchOpenLibraryAdvancedProvider =
    FutureProvider.family<List<OpenLibraryBook>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchOpenLibraryAdvanced(query);
});

/// Provider para buscar por ISBN en Open Library
final searchOpenLibraryByISBNProvider =
    FutureProvider.family<List<OpenLibraryBook>, String>((ref, isbn) async {
  if (isbn.isEmpty) return [];
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.searchOpenLibraryByISBN(isbn);
});

/// Provider para obtener detalles de un libro de Open Library
final openLibraryBookDetailsProvider =
    FutureProvider.family<OpenLibraryBook?, String>((ref, openLibraryId) async {
  final repo = ref.read(libraryRepositoryProvider);
  return await repo.getOpenLibraryBookDetails(openLibraryId);
});
