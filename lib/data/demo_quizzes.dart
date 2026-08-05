import '../models/models.dart';

class DemoQuizzes {
  static const List<Quiz> quizzes = [
    Quiz(
      id: 'flutter_basics',
      title: 'Flutter Basics',
      description: 'Core Flutter & Dart concepts for beginners.',
      questions: [
        Question(
          text: 'What language is Flutter built with?',
          options: ['JavaScript', 'Dart', 'Kotlin', 'Swift'],
          correctIndex: 1,
          explanation:
              'Flutter uses Dart, a client-optimized language developed by Google.',
        ),
        Question(
          text: 'What widget is the root of every Flutter app?',
          options: ['Container', 'Scaffold', 'MaterialApp', 'Center'],
          correctIndex: 2,
          explanation:
              'MaterialApp (or CupertinoApp) is the root widget that configures theme, routes, and more.',
        ),
        Question(
          text: 'Which widget provides the basic app structure with an AppBar?',
          options: ['Row', 'Scaffold', 'Column', 'Stack'],
          correctIndex: 1,
          explanation:
              'Scaffold gives the app a visual structure including AppBar, body, and FAB.',
        ),
        Question(
          text: 'StatefulWidget is used when...',
          options: [
            'The UI is static',
            'Widget state can change over time',
            'You need a layout',
            'You are testing',
          ],
          correctIndex: 1,
          explanation:
              'StatefulWidget allows mutable state that triggers rebuilds via setState().',
        ),
      ],
    ),
    Quiz(
      id: 'interview_prep',
      title: 'Interview Prep',
      description: 'Common software engineering interview questions.',
      questions: [
        Question(
          text: 'What is the time complexity of binary search?',
          options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'],
          correctIndex: 1,
          explanation:
              'Binary search halves the search space each step, giving O(log n).',
        ),
        Question(
          text: 'Which data structure operates FIFO?',
          options: ['Stack', 'Queue', 'Tree', 'Graph'],
          correctIndex: 1,
          explanation:
              'A Queue is First-In, First-Out; a Stack is LIFO.',
        ),
        Question(
          text: 'What does SOLID refer to?',
          options: [
            'A database standard',
            'Five design principles',
            'A testing framework',
            'A network protocol',
          ],
          correctIndex: 1,
          explanation:
              'SOLID is a set of five object-oriented design principles.',
        ),
      ],
    ),
  ];
}
