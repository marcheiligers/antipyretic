class Statement
  attr_reader :date

  class << self
    def statement_config(name, match_regexp, date_regexp = nil)
      config[:name] = name
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
        date: /(\d{1,2} [a-zA-Z]{3} \d{4})/,
        line: {
          match: /^\s*?(\d{2} [a-zA-Z]{3}) (.*?) ((\d+ )?\d{1,3}\.\d{2}( ?cr)?)/i,
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
    parse_date reader

    reader.each_line do |line|
      lines << config[:line][:constructor].new(line, self) if line.match? config[:line][:match]
    end

    lines.sort! { |a, b| a.date <=> b.date }
  end

  def config
    self.class.config
  end

  def name
    config[:name]
  end

  def lines
    @lines ||= []
  end

  def total
    lines.inject(0) { |a, l| a + l.amount }.round(2)
  end

  def parse_date(reader)
    date_match = nil
    begin
      date_match = reader.first_line do |line|
        line.match config[:date]
      end
      raise "Statement date not found" if date_match.nil?
      @date = Date.parse(date_match[1])
    rescue => e
      raise "Bad date (#{name})\n#{e.message}\n#{date_match.pretty_print if date_match}"
    end
  end
end