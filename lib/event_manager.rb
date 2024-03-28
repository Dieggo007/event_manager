# frozen_string_literal: true

require 'csv'
require 'erb'
require 'date'
require 'google/apis/civicinfo_v2'



def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.gsub(/\D/, '')
  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..]
  elsif phone_number.length < 10 || phone_number.length > 10
    'N/A'
  else
    phone_number
  end
end

def str_to_date_object(date_str)
  DateTime.strptime(date_str, '%m/%d/%y %H:%M')
end

def get_registration_hours(dates)
  registration_hours = Hash.new(0)
  dates.each do |date|
    registration_hours[date.hour] += 1
  end
  registration_hours.sort_by { |_, v| v * -1 }.each_with_object({}) do |array, hash|
    hash[array[0]] = array[1]
  end 
end

def get_registrations_weekdays(dates)
  weekdays = %i[sunday monday tuesday wednesday thursday friday saturday]
  registrations_days = Hash.new(0)
  dates.each do |date|
    registrations_days[weekdays[date.wday]] += 1
  end
  registrations_days.sort_by { |_, v| v * -1 }.each_with_object({}) do |array, hash|
    hash[array[0]] = array[1]
  end
end


puts 'EventManager Initialized!.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true, header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  dates.push(str_to_date_object(row[:regdate]))
  homephone = row[:homephone]
  zipcode = clean_zipcode(row[:zipcode])
  puts "#{id} #{name}, #{clean_phone_number(homephone)  }"
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

registration_hours = get_registration_hours(dates)
registration_days = get_registrations_weekdays(dates)
p registration_hours
p registration_days





