#!/usr/bin/env ruby

require 'csv'
require 'spreadsheet'

def safe_title(title)
  string = title.dup
  string.gsub!(/[^\w\s\d-]/, '')
  string.squeeze!(" ")

  string
end
unless File.exists?(ARGV[0].to_s)
  abort "Usage: convert_xls.rb input_data.xls"
end

jobs = Hash.new

puts "Opening #{ARGV[0]}..."
data = Spreadsheet.open(ARGV[0]).worksheet(0)
headers = data.row(0)

puts "Parsing #{ARGV[0]}..."
i = 0
data.each 1 do |r|
  print "." if i % 100 == 0
  title = safe_title(r[8])
  job = {
    :title => safe_title(r[8]),
    :job_code => r[7],
    :position_number => r[0],
    :unit_number => r[1],
    :unit_name => r[2],
    :time_equivalent => r[3],
    :salary => r[4].to_f.round(2),
    :fte_salary => r[5].to_f.round(2),
    :benefit_cost => r[6].to_f.round(2)
  }

  jobs[title] ||= []
  jobs[title] << job

  i += 1
end
puts "done!"

jobs.each do |title, data|
  # ugh
  safe_title = safe_title(title)
  print "Writing './data/#{safe_title}.csv' ..."
  CSV.open("./data/#{safe_title}.csv", "wb") do |csv|
    csv << data.first.keys.map(&:to_s)
    data.each { |d| csv << d.values }
  end
  puts "done!"
end

print "Writing summaries..."
CSV.open("./data/summary.csv", "wb") do |csv|
  csv << ["title", "num_salaries", "min", "max", "avg", "med"]
  jobs.each do |title, data|
    safe_title = safe_title(title)

    sorted = (data.map { |d| d[:salary].to_f }).sort
    num_salaries = sorted.length
    min = sorted.first
    max = sorted.last
    avg = ((sorted.inject(0.0, :+)) / num_salaries).round(2)
    med = ((sorted[(num_salaries - 1) / 2] + sorted[num_salaries / 2]) / 2.0).round(2)

    csv << [safe_title, num_salaries, min, max, avg, med]
  end
end
puts "done!"

print "Writing select options..."
File.open("./js/positions.js", "wb") do |f|
  f.puts <<-EOF
positions = ['Summary', #{jobs.keys.map { |t| "'#{t}'" }.join(', ')}];
  EOF
end
puts "done!"
