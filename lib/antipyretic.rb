require 'pdf-reader'
require 'date'
require 'singleton'
require 'yaml'

require_relative 'ext/string'
require_relative 'ext/pdf_reader'
require_relative 'ext/match_data'
require_relative 'ext/module'

require_relative 'processor'
require_relative 'statement'
require_relative 'statement_line'
require_relative 'classifier'
require_relative 'fnb_cheque'
require_relative 'fnb_card'
require_relative 'fnb_smart'

Processor.register_statement_type(FnbChequeStatement)
Processor.register_statement_type(FnbCardStatement)
Processor.register_statement_type(FnbSmartStatement)
