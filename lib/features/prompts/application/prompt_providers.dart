import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/features/prompts/data/prompt_repository.dart';

final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository();
});