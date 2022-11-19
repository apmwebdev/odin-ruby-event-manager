require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(num)
  formatted_num = num.gsub(/\D/, "")
  if formatted_num.length == 10
    formatted_num
  elsif formatted_num.length == 11 && formatted_num[0] == "1"
    formatted_num[-10..]
  else
    "-"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    )
    legislators.officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")
  filename = "output/thanks#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def create_contacts(contents)
  template = File.read("contacts.erb")
  erb_template = ERB.new template
  form_template = erb_template.result(binding)
  File.open("output/contacts.html", "w") { |file| file.puts form_template}
end

def parse_reg_time(time)
  begin
    Time.parse(time)
  rescue
    "Invalid time format"
  end
end

puts "EventManager initialized!"

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

# create_contacts(contents)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_number(row[:homephone])
  reg_datetime = parse_reg_time(row[:regdate])
  puts "#{name} reg time as string: #{row[:regdate]}, as time: #{reg_datetime}"
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
end
