class CalendarIntegrationService
  # iCalendar feed generation for bookings
  def self.generate_ical_for_user(user)
    bookings = user.managed_bookings.where(status: [:confirmed, :in_progress])
    
    ical = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Rentable//EN\r\n"
    
    bookings.each do |booking|
      ical += booking_to_ical_event(booking)
    end
    
    ical += "END:VCALENDAR\r\n"
    ical
  end

  def self.generate_ical_for_booking(booking)
    ical = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Rentable//EN\r\n"
    ical += booking_to_ical_event(booking)
    ical += "END:VCALENDAR\r\n"
    ical
  end

  # Google Calendar integration helper
  def self.google_calendar_url(booking)
    params = {
      action: 'TEMPLATE',
      text: "Booking: #{booking.reference_number}",
      dates: "#{format_google_date(booking.start_date)}/#{format_google_date(booking.end_date)}",
      details: "Customer: #{booking.customer_name}\nStatus: #{booking.status}",
      location: booking.venue_location&.name || ''
    }
    
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  # Outlook Calendar integration helper
  def self.outlook_calendar_url(booking)
    params = {
      path: '/calendar/action/compose',
      rru: 'addevent',
      subject: "Booking: #{booking.reference_number}",
      startdt: booking.start_date.iso8601,
      enddt: booking.end_date.iso8601,
      body: "Customer: #{booking.customer_name}\nStatus: #{booking.status}",
      location: booking.venue_location&.name || ''
    }
    
    "https://outlook.live.com/calendar/0/deeplink/compose?#{params.to_query}"
  end

  private

  def self.booking_to_ical_event(booking)
    event = "BEGIN:VEVENT\r\n"
    event += "UID:booking-#{booking.id}@rentable.com\r\n"
    event += "DTSTAMP:#{format_ical_date(Time.current)}\r\n"
    event += "DTSTART:#{format_ical_date(booking.start_date)}\r\n"
    event += "DTEND:#{format_ical_date(booking.end_date)}\r\n"
    event += "SUMMARY:Booking: #{booking.reference_number}\r\n"
    event += "DESCRIPTION:Customer: #{booking.customer_name}\\nStatus: #{booking.status}\r\n"
    event += "LOCATION:#{booking.venue_location&.name || ''}\r\n"
    event += "STATUS:#{booking.confirmed? ? 'CONFIRMED' : 'TENTATIVE'}\r\n"
    event += "END:VEVENT\r\n"
    event
  end

  def self.format_ical_date(datetime)
    datetime.utc.strftime('%Y%m%dT%H%M%SZ')
  end

  def self.format_google_date(datetime)
    datetime.utc.strftime('%Y%m%dT%H%M%SZ')
  end
end
