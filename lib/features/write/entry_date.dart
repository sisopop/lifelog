/// Combines a chosen calendar [day] with the time-of-day from [base] so an
/// entry written for a past date still keeps a sensible within-day ordering.
DateTime composeEntryDate(DateTime day, DateTime base) => DateTime(
      day.year,
      day.month,
      day.day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
    );
