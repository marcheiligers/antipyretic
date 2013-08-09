class Processor
  include Singleton

  attr_reader :statements

  class << self
    delegate  :register_statement_type,
              :process_file,
              :statement_type,
              :lines,
              :to => :instance
  end

  # def self.register_statement_type(type)
  #   instance.register_statement_type type
  # end

  def initialize
    @registered_statement_types = []
    @statements = []
  end

  def register_statement_type(type)
    raise "#{type} is not a Statement" unless type.ancestors.include? Statement
    @registered_statement_types << type
  end

  def statement_type(reader)
    @registered_statement_types.detect do |type|
      type.matches?(reader)
    end
  end

  def process_file(filename)
    puts "Processing file #{filename}"
    reader = PDF::Reader.new filename
    type = statement_type reader

    raise "#{filename} is an unrecognized statement type" unless type
    statement = type.process(reader)
    statements << statement if statements.none? { |s| s.name == statement.name && s.date == statement.date }
  end

  def lines
    statements.map(&:lines).flatten.sort { |a, b| a.date <=> b.date }
  end
end
