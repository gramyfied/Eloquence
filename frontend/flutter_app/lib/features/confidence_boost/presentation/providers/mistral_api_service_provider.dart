import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/mistral_api_service.dart';

final mistralApiServiceProvider = Provider<IMistralApiService>((ref) {
  return MistralApiService();
});