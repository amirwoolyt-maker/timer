class AppStrings {
  const AppStrings(this.isEnglish);
  final bool isEnglish;

  String get tasks => isEnglish ? 'Tasks' : 'کارهای من';
  String get timer => isEnglish ? 'Focus' : 'تمرکز';
  String get notes => isEnglish ? 'Notes' : 'یادداشت‌ها';
  String get social => isEnglish ? 'Community' : 'همراهان';
  String get more => isEnglish ? 'Explore' : 'بیشتر';
  String get today => isEnglish ? 'today' : 'امروز';
  String get addTask => isEnglish ? 'New task' : 'کار تازه';
  String get addNote => isEnglish ? 'New note' : 'یادداشت تازه';
  String get search => isEnglish ? 'Search' : 'جستجو';
  String get all => isEnglish ? 'All' : 'همه';
  String get done => isEnglish ? 'Done' : 'انجام‌شده';
  String get remaining => isEnglish ? 'Remaining' : 'در پیش';
  String get emptyTasks => isEnglish
      ? 'Your day is wide open.'
      : 'امروز، روز تازه‌ای برای شروع است.';
  String get emptyNotes => isEnglish
      ? 'Save your thoughts here.'
      : 'فکرها و ایده‌هایت را اینجا نگه دار.';
  String get save => isEnglish ? 'Save' : 'ذخیره';
  String get cancel => isEnglish ? 'Cancel' : 'بی‌خیال';
  String get title => isEnglish ? 'Title' : 'عنوان';
  String get description => isEnglish ? 'Description' : 'توضیحات';
  String get profile => isEnglish ? 'Profile' : 'پروفایل';
}
