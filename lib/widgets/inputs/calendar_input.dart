import 'package:flutter/material.dart';

class CalendarInput extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;

  const CalendarInput({super.key, this.onDateSelected, this.initialDate});

  @override
  State<CalendarInput> createState() => _CalendarInputState();
}

class _CalendarInputState extends State<CalendarInput> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 366,
      color: const Color(0xFFDAE4E1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), _buildWeekdayHeader(), _buildCalendarDays()],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: _previousMonth,
          ),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: const TextStyle(
              color: Color(0xFF373C3A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Helvetica Now Display',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return SizedBox(
      height: 40,
      child: Row(
        children:
            weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF8E8C9A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Victor Mono',
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCalendarDays() {
    final DateTime firstDayOfMonth = _currentMonth;

    // Calculate the first day of the calendar grid (may be from previous month)
    final int firstWeekday =
        firstDayOfMonth.weekday % 7; // 0 for Sunday as first day
    final DateTime firstCalendarDay = firstDayOfMonth.subtract(
      Duration(days: firstWeekday),
    );

    // Generate weeks
    List<List<DateTime>> weeks = [];
    DateTime day = firstCalendarDay;

    // Always generate exactly 6 weeks for consistent height
    for (int w = 0; w < 6; w++) {
      List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(day);
        day = day.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    // Always show all 6 weeks for consistent height
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: weeks.map((week) => _buildWeek(week)).toList(),
    );
  }

  Widget _buildWeek(List<DateTime> days) {
    return SizedBox(
      height: 40,
      child: Row(children: days.map((day) => _buildDayCell(day)).toList()),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final bool isCurrentMonth = day.month == _currentMonth.month;
    final bool isSelected =
        day.year == _selectedDate.year &&
        day.month == _selectedDate.month &&
        day.day == _selectedDate.day;

    return Expanded(
      child: GestureDetector(
        onTap: isCurrentMonth ? () => _selectDate(day) : null,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF05022) : Colors.transparent,
            ),
            child: Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : const Color(
                            0xFF373C3A,
                          ).withOpacity(isCurrentMonth ? 1.0 : 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Victor Mono',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
