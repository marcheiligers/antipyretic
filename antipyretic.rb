require 'pdf-reader'
require 'date'

class String
  def blank?
    self.strip == ''
  end
end

class Processor
  attr_reader :statements

  def initialize
    @registered_statement_types = []
    @statements = []
  end

  def register_statement_type(statement_type)
    raise "#{statement_type} is not a Statement" unless statement_type.ancestors.include? Statement
    @registered_statement_types << statement_type
  end

  def statement_type(reader)
    @registered_statement_types.detect do |statement_type|
      statement_type.matches?(reader)
    end
  end

  def process_file(filename)
    reader = PDF::Reader.new filename
    klass = statement_type reader
    raise "#{filename} is an unrecognized statement" unless klass
    klass.process reader
  end
end

class Statement
  def self.matches?(reader)
    false
  end

  def self.process(reader)
    new reader
  end

  def lines
    @lines ||= []
  end

  def total
    lines.inject(0) { |a, l| a + l.amount }.round(2)
  end

  def each_line(reader)
    reader.pages.each do |page|
      page.text.each_line do |line|
        yield line
      end
    end
  end
end

class FnbChequeStatement < Statement
  def self.matches?(reader)
    reader.pages.first.text.each_line do |line|
      return true if line.include? 'CHEQUE ACCOUNT'
    end
    false
  end

  def initialize(reader)
    found_opening = false

    each_line reader do |line|
      if found_opening
        if line.include? 'Closing Balance'
          found_opening = false
        else
          lines << FnbChequeLine.new(line) unless line.blank?
        end
      elsif line.include?('Opening Balance') && line.include?('0.00')
        found_opening = true
      end
    end
  end

end

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

class FnbCardStatement < Statement
  DATE_REGEX = /Statement Date (\d{1,2} \w{3} \d{4})/

  attr_reader :date

  def self.matches?(reader)
    reader.pages.first.text.each_line do |line|
      return true if line.include? 'CREDIT ACCOUNT'
    end
    false
  end

  def initialize(reader)
    found_opening = false
    find_date reader

    each_line reader do |line|
      if line.match(/^ \d\d \w\w\w /)
        lines << FnbCardLine.new(line, self) unless line.blank?
      end
    end

    lines.sort! { |a, b| a.date <=> b.date }
  end

  def find_date(reader)
    each_line reader do |line|
      match = line.match DATE_REGEX
      return @date = Date.parse(match[1]) if match
    end
  end
end

class FnbCardLine
  attr_reader :statement, :date, :amount, :description

  def initialize(line, statement)
    @statement = statement

    data = line.strip.split(/\s{2,}/)
    day, month, *main_desc = data[0].strip.split(' ')

    @date = Date.parse("#{day} #{month} #{statement.date.year}")

    amount_index = data[-1].gsub(' ', '').to_f == 0 ? -2 : -1
    @amount = data[amount_index].gsub(' ', '').to_f
    @amount *= -1 if data[amount_index].downcase.end_with?('cr')

    @description = (main_desc.join(' ') + '  ' + data[1..amount_index - 1].join(' ')).strip
  end

  def to_s
    "#{date} #{description} #{'%0.2f' % amount}"
  end
end

processor = Processor.new
processor.register_statement_type(FnbChequeStatement)
processor.register_statement_type(FnbCardStatement)
statement = processor.process_file '/Users/marc/Documents/Financial/Statements/FNB Card 2012-09-26.pdf'

puts statement.lines.map(&:to_s)
puts "Total: #{statement.total}"