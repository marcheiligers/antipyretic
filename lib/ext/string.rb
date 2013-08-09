class String
  def blank?
    self.strip == ''
  end

  def match?(regexp)
    !self.match(regexp).nil?
  end
end
