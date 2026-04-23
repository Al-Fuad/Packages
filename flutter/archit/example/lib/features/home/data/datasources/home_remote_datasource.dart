import '../../../../core/network/api_client.dart';
import '../models/home_model.dart';

abstract class HomeRemoteDataSource {
  // Add your remote data source methods here

  Future<void> fetchProducts();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient apiClient;

  HomeRemoteDataSourceImpl({required this.apiClient});

  // Implement methods here

  @override
  Future<void> fetchProducts() async {
    // TODO: implement fetchProducts
    throw UnimplementedError();
  }
}
