class Classifier
  class Rule
    attr_reader :tag, :parts

    def initialize(tag, parts)
      @tag = tag
      @parts = parts #.symbolize_keys
    end

    def applies?(line)
      result = true
      result &&= amount_applies?(line) if parts[:amount]
      result &&= regexp_applies?(line) if parts[:regexp]
      result &&= date_applies?(line) if parts[:date]
      result
    end

    def amount_applies?(line)
      method, value = parts[:amount].match(/(.*?)\s*(-?[\d,\.]+)/).captures
      line.amount.send(method, value.to_f)
    end

    def regexp_applies?(line)
      line.description.match? Regexp.new(parts[:regexp], Regexp::IGNORECASE)
    end

    def date_applies?(line)
      method, value = parts[:date].match(/(.*?)\s*(\d+.*)/).captures
      line.date.send(method, Date.parse(value))
    end
  end

  include Singleton

  class << self
    delegate  :add,
              :load,
              :classify,
              :to => :instance
  end

  def rules
    @rules ||= []
  end

  def add(tag, parts)
    rules << Rule.new(tag, parts)
  end

  def load(filename)
    YAML.load(File.read(filename)).each do |rule|
      add rule.delete(:tag), rule
    end
  end

  def classify(line)
    rules.each do |rule|
      line.tags << rule.tag if rule.applies?(line) && !line.tags.include?(rule.tag)
    end
  end
end
