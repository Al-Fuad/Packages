import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  // Define repository contracts here

  Future<Either<Failure, void>> login();
}
