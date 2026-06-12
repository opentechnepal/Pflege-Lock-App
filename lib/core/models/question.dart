class Question {
  final int? id;
  final String category;
  final String difficulty;
  final String promptDe;
  final String correctAnswer;
  final String wrongOpt1;
  final String wrongOpt2;
  final String wrongOpt3;
  final String? explanation;

  const Question({
    this.id,
    required this.category,
    this.difficulty = 'medium',
    required this.promptDe,
    required this.correctAnswer,
    required this.wrongOpt1,
    required this.wrongOpt2,
    required this.wrongOpt3,
    this.explanation,
  });

  List<String> get allOptions => [correctAnswer, wrongOpt1, wrongOpt2, wrongOpt3];

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String? ?? 'medium',
      promptDe: map['prompt_de'] as String,
      correctAnswer: map['correct_answer'] as String,
      wrongOpt1: map['wrong_opt_1'] as String,
      wrongOpt2: map['wrong_opt_2'] as String,
      wrongOpt3: map['wrong_opt_3'] as String,
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'difficulty': difficulty,
      'prompt_de': promptDe,
      'correct_answer': correctAnswer,
      'wrong_opt_1': wrongOpt1,
      'wrong_opt_2': wrongOpt2,
      'wrong_opt_3': wrongOpt3,
      'explanation': explanation,
    };
  }
}
