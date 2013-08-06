require 'pdf-reader'
require 'date'


unless ARGV[0]
  puts "Usage: pdf2text filename"
  exit
end

reader = PDF::Reader.new ARGV[0]
reader.pages.each do |page|
  puts page.text
end
