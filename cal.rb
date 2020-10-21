require 'rubygems'
require 'google_calendar'
require 'dotenv/load'
require 'active_support/core_ext/numeric/time'
require 'icalendar'
require 'rack'
require 'rack/server'
require_relative 'basic_auth'

Dotenv.require_keys(
  "TIMEZONE",
  "CLIENT_ID",
  "CLIENT_SECRET",
  "CALENDAR",
  "USERNAME",
  "PASSWORD",
)

class CalendarApp
  def initialize(cal)
    @cal = cal
    @cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 5.minutes)
  end

  def call(env)
    if env["PATH_INFO"] == "/calendar.ical"
      [ 200, { 'Content-Type' => "text/calendar" }, [ format_events_into_ical ] ]
    else
      [ 404, { }, [ "Not Found" ] ]
    end
  end

  def format_events_into_ical
    @cache.fetch("calendar") do
      puts "Fetching and formatting Google Calendar"
      min_time = Time.now.in_time_zone(ENV['TIMEZONE'])
      max_time = (Time.now + (86400 * 7)).end_of_day
    
      icalendar = Icalendar::Calendar.new
      @cal.find_events_in_range(min_time, max_time).each do |event|
        start_time = Time.parse(event.start_time)
        end_time = Time.parse(event.end_time)
        icalendar.event do |e|
          e.dtstart      = Icalendar::Values::DateTime.new(start_time, tzid: start_time.zone)
          e.dtend        = Icalendar::Values::DateTime.new(end_time, tzid: end_time.zone)
          e.summary      = event.title
          e.description  = event.description
          e.ip_class     = event.visibility.upcase
          e.url          = event.html_link
          e.status       = event.status
        end
      end
    
      icalendar.to_ical
    end
  end
end

def get_google_calendar
  cal = Google::Calendar.new(
    client_id: ENV["CLIENT_ID"],
    client_secret: ENV["CLIENT_SECRET"],
    calendar: ENV["CALENDAR"],
    redirect_url: "urn:ietf:wg:oauth:2.0:oob" # this is what Google uses for 'applications'
  )

  refresh_token = ENV["REFRESH_TOKEN"]

  if refresh_token.nil?
    # A user needs to approve access in order to work with their calendars.
    puts "Visit the following web page in your browser and approve access."
    puts cal.authorize_url
    puts "\nCopy the code that Google returned and paste it here:"

    # Pass the ONE TIME USE access code here to login and get a refresh token that you can use for access from now on.
    refresh_token = cal.login_with_auth_code( $stdin.gets.chomp )

    puts "\nMake sure you SAVE YOUR REFRESH TOKEN to `.env` under `REFRESH_TOKEN` so you don't have to prompt the user to approve access again."
    puts "Your refresh token is:\n\t#{refresh_token}\n"
    puts "Press return to continue"
    $stdin.gets.chomp
  else
    cal.login_with_refresh_token(refresh_token)
  end

  cal
end

app = Rack::Builder.new do |builder|
  builder.use BasicAuth
  builder.run CalendarApp.new(get_google_calendar)
end
Rack::Server.start(app: app)
