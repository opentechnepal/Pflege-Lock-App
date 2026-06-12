import 'package:pflege_lock_app/core/database/database_helper.dart';
import 'package:pflege_lock_app/core/models/question.dart';

class QuestionRepository {
  QuestionRepository(this._db);
  final DatabaseHelper _db;

  Future<Question?> getRandomQuestion(List<String> categories) {
    return _db.getRandomQuestion(categories);
  }
}
