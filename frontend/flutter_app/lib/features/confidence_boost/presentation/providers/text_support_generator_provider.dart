import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/text_support_generator.dart';

final textSupportGeneratorProvider = Provider<TextSupportGenerator>((ref) {
  // .create attend un Ref, et le 'ref' d'un provider est du bon type.
  return TextSupportGenerator.create(ref);
});