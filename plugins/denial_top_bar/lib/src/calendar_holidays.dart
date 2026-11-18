/// Mainland China public holiday arrangements announced by the State Council.
///
/// Data is available only for years with an official annual schedule (2025–2027).
/// Dates are matched by civil year, month, and day; the time and time zone on
/// [date] are ignored. A non-makeup entry is a scheduled day off. Makeup
/// workdays are included separately because they can fall on weekends.
CalendarHoliday? chinesePublicHoliday(DateTime date) =>
    _chinesePublicHolidays[_civilDateKey(date)];

int _civilDateKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

/// One day in an officially announced mainland China holiday arrangement.
class CalendarHoliday {
  const CalendarHoliday({
    required this.chineseName,
    required this.englishName,
    required this.isMakeUpWorkday,
  });

  final String chineseName;
  final String englishName;
  final bool isMakeUpWorkday;

  String label({required bool chinese}) {
    if (isMakeUpWorkday) return chinese ? chineseName : englishName;
    return chinese ? '$chineseName · 放假' : '$englishName · Day off';
  }
}

const _newYear = CalendarHoliday(
  chineseName: '元旦',
  englishName: 'New Year',
  isMakeUpWorkday: false,
);
const _springFestival = CalendarHoliday(
  chineseName: '春节',
  englishName: 'Spring Festival',
  isMakeUpWorkday: false,
);
const _qingming = CalendarHoliday(
  chineseName: '清明节',
  englishName: 'Qingming Festival',
  isMakeUpWorkday: false,
);
const _laborDay = CalendarHoliday(
  chineseName: '劳动节',
  englishName: 'Labor Day',
  isMakeUpWorkday: false,
);
const _dragonBoat = CalendarHoliday(
  chineseName: '端午节',
  englishName: 'Dragon Boat Festival',
  isMakeUpWorkday: false,
);
const _midAutumn = CalendarHoliday(
  chineseName: '中秋节',
  englishName: 'Mid-Autumn Festival',
  isMakeUpWorkday: false,
);
const _nationalDay = CalendarHoliday(
  chineseName: '国庆节',
  englishName: 'National Day',
  isMakeUpWorkday: false,
);
const _nationalDayAndMidAutumn = CalendarHoliday(
  chineseName: '国庆节、中秋节',
  englishName: 'National Day and Mid-Autumn Festival',
  isMakeUpWorkday: false,
);

const _makeUpWorkday = CalendarHoliday(
  chineseName: '调休上班',
  englishName: 'Make-up workday',
  isMakeUpWorkday: true,
);

const Map<int, CalendarHoliday> _chinesePublicHolidays = {
  // 2025: https://www.gov.cn/zhengce/content/202411/content_6986382.htm
  20250101: _newYear,
  20250126: _makeUpWorkday,
  20250128: _springFestival,
  20250129: _springFestival,
  20250130: _springFestival,
  20250131: _springFestival,
  20250201: _springFestival,
  20250202: _springFestival,
  20250203: _springFestival,
  20250204: _springFestival,
  20250208: _makeUpWorkday,
  20250404: _qingming,
  20250405: _qingming,
  20250406: _qingming,
  20250427: _makeUpWorkday,
  20250501: _laborDay,
  20250502: _laborDay,
  20250503: _laborDay,
  20250504: _laborDay,
  20250505: _laborDay,
  20250531: _dragonBoat,
  20250601: _dragonBoat,
  20250602: _dragonBoat,
  20250928: _makeUpWorkday,
  20251001: _nationalDayAndMidAutumn,
  20251002: _nationalDayAndMidAutumn,
  20251003: _nationalDayAndMidAutumn,
  20251004: _nationalDayAndMidAutumn,
  20251005: _nationalDayAndMidAutumn,
  20251006: _nationalDayAndMidAutumn,
  20251007: _nationalDayAndMidAutumn,
  20251008: _nationalDayAndMidAutumn,
  20251011: _makeUpWorkday,

  // 2026: https://www.gov.cn/zhengce/content/202511/content_7047090.htm
  20260101: _newYear,
  20260102: _newYear,
  20260103: _newYear,
  20260104: _makeUpWorkday,
  20260214: _makeUpWorkday,
  20260215: _springFestival,
  20260216: _springFestival,
  20260217: _springFestival,
  20260218: _springFestival,
  20260219: _springFestival,
  20260220: _springFestival,
  20260221: _springFestival,
  20260222: _springFestival,
  20260223: _springFestival,
  20260228: _makeUpWorkday,
  20260404: _qingming,
  20260405: _qingming,
  20260406: _qingming,
  20260501: _laborDay,
  20260502: _laborDay,
  20260503: _laborDay,
  20260504: _laborDay,
  20260505: _laborDay,
  20260509: _makeUpWorkday,
  20260619: _dragonBoat,
  20260620: _dragonBoat,
  20260621: _dragonBoat,
  20260920: _makeUpWorkday,
  20260925: _midAutumn,
  20260926: _midAutumn,
  20260927: _midAutumn,
  20261001: _nationalDay,
  20261002: _nationalDay,
  20261003: _nationalDay,
  20261004: _nationalDay,
  20261005: _nationalDay,
  20261006: _nationalDay,
  20261007: _nationalDay,
  20261010: _makeUpWorkday,

  // 2027: https://www.gov.cn/zhengce/zhengceku/202611/content_7085102.htm
  20270101: _newYear,
  20270102: _newYear,
  20270103: _newYear,
  20270131: _makeUpWorkday,
  20270205: _springFestival,
  20270206: _springFestival,
  20270207: _springFestival,
  20270208: _springFestival,
  20270209: _springFestival,
  20270210: _springFestival,
  20270211: _springFestival,
  20270212: _springFestival,
  20270213: _springFestival,
  20270214: _makeUpWorkday,
  20270403: _qingming,
  20270404: _qingming,
  20270405: _qingming,
  20270501: _laborDay,
  20270502: _laborDay,
  20270503: _laborDay,
  20270504: _laborDay,
  20270505: _laborDay,
  20270508: _makeUpWorkday,
  20270609: _dragonBoat,
  20270915: _midAutumn,
  20270926: _makeUpWorkday,
  20271001: _nationalDay,
  20271002: _nationalDay,
  20271003: _nationalDay,
  20271004: _nationalDay,
  20271005: _nationalDay,
  20271006: _nationalDay,
  20271007: _nationalDay,
  20271009: _makeUpWorkday,
};
