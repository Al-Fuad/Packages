import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class FetchProductsUseCase implements UseCase<void, NoParams> {
  final HomeRepository repository;

  FetchProductsUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.fetchProducts();
  }
}
