require 'pdf-reader'
require 'date'

require_relative 'ext/string.rb'
require_relative 'ext/pdf_reader.rb'

require_relative 'statement.rb'
require_relative 'fnb_cheque.rb'
require_relative 'fnb_card.rb'

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
