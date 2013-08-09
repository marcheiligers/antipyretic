class StatementLine
  AMOUNT_CLEANUP_REGEX = /(,| )/

  attr_reader :account, :date, :amount, :description, :tags

  def initialize(line, statement)
    @statement = statement
    @tags = []
    parse line
    Classifier.classify self
  end

  def config
    @statement.config[:line]
  end

  def parse(line)
    match = line.match config[:match]

    @date = parse_date match[config[:positions][:date]]
    @description = match[config[:positions][:description]].squeeze(' ').strip
    @amount = parse_amount match[config[:positions][:amount]], match[config[:positions][:credit]]
  rescue => e
    raise "Bad line (#{@statement.name})\n#{e.message}\n#{'-' * 80}\n#{line}\n#{'-' * 80}\n#{match.pretty_print}"
  end

  def parse_date(day_month_string)
    @date = check_date(Date.parse("#{day_month_string} #{@statement.date.year}"))
  end

  def check_date(date)
    date < @statement.date.prev_month(3) ?
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