import '../../../../core/network/api_client.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  // Add your remote data source methods here

  Future<void> login();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  // Implement methods here

  @override
  Future<void> login() async {
    // TODO: implement login
    throw UnimplementedError();
  }
}
