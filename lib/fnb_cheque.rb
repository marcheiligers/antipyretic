class FnbChequeStatement < Statement
  statement_config 'FNB Cheque ℀', /CHEQUE ACCOUNT/, /\d{1,2} \w{3,} \d{4} to (\d{1,2} \w{3,} \d{4})/
  line_config /^\s*(\d{2} \w{3}) (.*?) ((\d+,)?\d{1,3}\.\d{2}( cr)?)\s+((\d+,)\d{1,3}\.\d{2}( cr)?)\s+((\d*,)?\d{1,3}\.\d{2}( cr)?)?/i
end