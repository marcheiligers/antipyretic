require 'pdf-reader'
require 'date'

class String
  def blank?
    self.strip == ''
  end
end

reader = PDF::Reader.new('/Users/marc/Documents/Financial/Statements/2013-05-18_Cheque.pdf')

statement_lines = []
found_opening = false

class FnbChequeLine
  attr_reader :account, :date, :amount, :description

  def initialize(line, account = 'cheque', year = 2013)
    @account = account

    data = line.strip.split(/\s{2,}/)
    day, month, *main_desc = data[0].split(' ')

    @date = Date.parse("#{day} #{month} #{year}")

    @amount = data[-3].gsub(',', '').to_f
    @amount *= -1 if data[-3].downcase.end_with?('cr')

    @description = main_desc.join(' ') + data[1..-4].join('  ')
  end

  def to_s
    "#{date} #{description} #{'%0.2f' % amount}"
  end
end

reader.pages.each do |page|
  page.text.each_line do |line|
    if found_opening
      if line.include? 'Closing Balance'
        found_opening = false
      else
        statement_lines << FnbChequeLine.new(line) unless line.blank?
      end
    elsif line.include?('Opening Balance') && line.include?('0.00')
      found_opening = true
    end
  end
end

puts statement_lines.map(&:to_s)