import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class HomeRepository {
  // Define repository contracts here

  Future<Either<Failure, void>> fetchProducts();
}
