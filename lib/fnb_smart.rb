class FnbSmartStatement < Statement
  statement_config 'FNB Card', /SMART ACCOUNT/, /(\d{1,2} \w{3,} \d{4}) to (\d{1,2} \w{3,} \d{4})/
  line_config /(\d{2} \w{3}) (.*?) ((\d+,)?\d{1,3}\.\d{2}( cr)?)\s+((\d+,)\d{1,3}\.\d{2}( cr)?)\s+((\d*,)?\d{1,3}\.\d{2}( cr)?)?/i
end