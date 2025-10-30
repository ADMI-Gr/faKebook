class BookModel {
  final String id;
  final String openLibraryId;
  final String title;
  final String? author;
  final String? isbn;
  final String? coverUrl;
  final int totalCopies;
  final int availableCopies;
  final int rentalDurationDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.openLibraryId,
    required this.title,
    this.author,
    this.isbn,
    this.coverUrl,
    required this.totalCopies,
    required this.availableCopies,
    required this.rentalDurationDays,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => availableCopies > 0;

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String,
      openLibraryId: map['open_library_id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      isbn: map['isbn'] as String?,
      coverUrl: map['cover_url'] as String?,
      totalCopies: map['total_copies'] as int,
      availableCopies: map['available_copies'] as int,
      rentalDurationDays: map['rental_duration_days'] as int,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'open_library_id': openLibraryId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_url': coverUrl,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'rental_duration_days': rentalDurationDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BookModel copyWith({
    String? id,
    String? openLibraryId,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    int? totalCopies,
    int? availableCopies,
    int? rentalDurationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      openLibraryId: openLibraryId ?? this.openLibraryId,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      rentalDurationDays: rentalDurationDays ?? this.rentalDurationDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BookRentalModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime rentedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final int extensionsCount;
  final RentalStatus status;

  // Información del libro (join)
  final BookModel? book;

  BookRentalModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.rentedAt,
    required this.dueDate,
    this.returnedAt,
    required this.extensionsCount,
    required this.status,
    this.book,
  });

  bool get isOverdue =>
      status == RentalStatus.active &&
      DateTime.now().isAfter(dueDate) &&
      returnedAt == null;

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  bool get canExtend => extensionsCount < 2 && status == RentalStatus.active;

  factory BookRentalModel.fromMap(Map<String, dynamic> map) {
    return BookRentalModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      bookId: map['book_id'] as String,
      rentedAt: DateTime.parse(map['rented_at']),
      dueDate: DateTime.parse(map['due_date']),
      returnedAt: map['returned_at'] != null
          ? DateTime.parse(map['returned_at'])
          : null,
      extensionsCount: map['extensions_count'] as int,
      status: RentalStatus.fromString(map['status'] as String),
      book: map['books'] != null ? BookModel.fromMap(map['books']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'rented_at': rentedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'extensions_count': extensionsCount,
      'status': status.value,
    };
  }
}

enum RentalStatus {
  active('active'),
  returned('returned'),
  overdue('overdue');

  final String value;
  const RentalStatus(this.value);

  static RentalStatus fromString(String value) {
    return RentalStatus.values.firstWhere((e) => e.value == value);
  }
}

class BookRequestModel {
  final String id;
  final String userId;
  final String openLibraryId;
  final String title;
  final String? author;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? notes;

  BookRequestModel({
    required this.id,
    required this.userId,
    required this.openLibraryId,
    required this.title,
    this.author,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.notes,
  });

  factory BookRequestModel.fromMap(Map<String, dynamic> map) {
    return BookRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      openLibraryId: map['open_library_id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      status: RequestStatus.fromString(map['status'] as String),
      requestedAt: DateTime.parse(map['requested_at']),
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'])
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'open_library_id': openLibraryId,
      'title': title,
      'author': author,
      'status': status.value,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

enum RequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  added('added');

  final String value;
  const RequestStatus(this.value);

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere((e) => e.value == value);
  }
}

// Modelo para libros de Open Library API
class OpenLibraryBook {
  final String openLibraryId;
  final String title;
  final List<String> authors;
  final String? isbn;
  final String? coverUrl;
  final String? description;
  final int? publishYear;

  OpenLibraryBook({
    required this.openLibraryId,
    required this.title,
    required this.authors,
    this.isbn,
    this.coverUrl,
    this.description,
    this.publishYear,
  });

  factory OpenLibraryBook.fromJson(Map<String, dynamic> json) {
    // Parseo simplificado, ajustar según la respuesta real de la API
    return OpenLibraryBook(
      openLibraryId: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Sin título',
      authors: (json['author_name'] as List?)?.cast<String>() ?? [],
      isbn:
          (json['isbn'] as List?)?.isNotEmpty == true ? json['isbn'][0] : null,
      coverUrl: json['cover_i'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_i']}-L.jpg'
          : null,
      publishYear: json['first_publish_year'] as int?,
    );
  }
}
