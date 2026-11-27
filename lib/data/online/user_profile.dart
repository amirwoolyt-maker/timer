const educationGrades = <String, String>{
  'elementary': 'ابتدایی',
  '7': 'هفتم',
  '8': 'هشتم',
  '9': 'نهم',
  '10': 'دهم',
  '11': 'یازدهم',
  '12': 'دوازدهم',
  'student': 'دانشجو',
  'graduate': 'فارغ‌التحصیل',
};

const profileAvatars = <String, ({String emoji, String label})>{
  'fox': (emoji: '🦊', label: 'روباه'),
  'cat': (emoji: '🐱', label: 'گربه'),
  'rabbit': (emoji: '🐰', label: 'خرگوش'),
  'panda': (emoji: '🐼', label: 'پاندا'),
  'owl': (emoji: '🦉', label: 'جغد'),
  'butterfly': (emoji: '🦋', label: 'پروانه'),
  'flower': (emoji: '🌸', label: 'شکوفه'),
  'moon': (emoji: '🌙', label: 'ماه'),
  'planet': (emoji: '🪐', label: 'سیاره'),
  'robot': (emoji: '🤖', label: 'ربات'),
  'unicorn': (emoji: '🦄', label: 'تک‌شاخ'),
  'cherry': (emoji: '🍒', label: 'گیلاس'),
};

/// Private account preferences; only the display name is copied to public posts.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.age,
    this.grade = '',
    this.gender = '',
    this.avatar = '',
    this.subject = '',
  });
  final String name, grade, gender, avatar, subject;
  final int? age;
  bool get complete =>
      name.trim().isNotEmpty &&
      name.trim().length <= 60 &&
      age != null &&
      age! >= 6 &&
      age! <= 100 &&
      educationGrades.containsKey(grade) &&
      const ['female', 'male', 'unspecified'].contains(gender) &&
      profileAvatars.containsKey(avatar) &&
      subject.length <= 60;
  factory UserProfile.fromMap(
    Map<dynamic, dynamic> values, {
    String name = '',
  }) => UserProfile(
    name: '${values['name'] ?? name}',
    age: int.tryParse('${values['age'] ?? ''}'),
    grade: '${values['grade'] ?? ''}',
    gender: '${values['gender'] ?? ''}',
    avatar: '${values['avatar'] ?? ''}',
    subject: '${values['subject'] ?? ''}',
  );
  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'age': age,
    'grade': grade,
    'gender': gender,
    'avatar': avatar,
    'subject': subject.trim(),
  };
}
