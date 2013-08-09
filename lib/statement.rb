class Statement
  attr_reader :date

  class << self
    def statement_config(name, match_regexp, date_regexp = nil)
      config[:match] = match_regexp
      config[:date] = date_regexp unless date_regexp.nil?
    end

    def line_config(match_regexp, constructor = StatementLine, positions = {})
      config[:line].merge!(
        match: match_regexp,
        constructor: constructor,
        positions: config[:line][:positions].merge(positions)
      )
    end

    def matches?(reader)
      reader.any_line? do |line|
        line.match config[:match]
      end
    end

    def process(reader)
      new reader
    end

    def config
      @config ||= {
        name: 'Generic Statement',
        match: /$unmatchable/,
        date: /(\d{1,2} \w{3} \d{4})/,
        line: {
          match: /^\s*?(\d{2} \w{3}) (.*?) ((\d+ )?\d{1,3}\.\d{2}( ?cr)?)/i,
          constructor: StatementLine,
          positions: {
            date: 1,
            description: 2,
            amount: 3,
            credit: 5
          }
        }
      }
    end
  end

  def initialize(reader)
    date_match = reader.first_line do |line|
      line.match config[:date]
    end
    raise "Statement date not found" if date_match.nil?
    @date = Date.parse(date_match[1])

    reader.each_line do |line|
      lines << config[:line][:constructor].new(line, self) if line.match? config[:line][:match]
    end

    lines.sort! { |a, b| a.date <=> b.date }
  end

  def config
    self.class.config
  end

  def lines
    @lines ||= []
  end

  def total
    lines.inject(0) { |a, l| a + l.amount }.round(2)
  end
end

class StatementLine
  AMOUNT_CLEANUP_REGEX = /(,| )/

  attr_reader :account, :date, :amount, :description

  def initialize(line, statement)
    @statement = statement
    parse line
  end

  def config
    @statement.config[:line]
  end

  def parse(line)
    match = line.match config[:match]

    @date = parse_date match[config[:positions][:date]]
    @description = match[config[:positions][:description]].squeeze.strip
    @amount = parse_amount match[config[:positions][:amount]], match[config[:positions][:credit]]
  rescue => e
    raise e
    raise "Bad line:\n  #{line}\n\n#{match.inspect}"
  end

  def parse_date(day_month_string)
    @date = check_date(Date.parse("#{day_month_string} #{@statement.date.year}"))
  end

  def check_date(date)
    date < @statement.date ?
      Date.new(date.year + 1, date.month, date.day) :
      date
  end

  def parse_amount(amount_string, credit = false)
    posneg = credit === true || credit.to_s.downcase.strip == 'cr' ? 1 : -1
    posneg * amount_string.gsub(AMOUNT_CLEANUP_REGEX, '').to_f
  end

  def to_s
    "#{date} #{description} #{'%0.2f' % amount}"
  end
end