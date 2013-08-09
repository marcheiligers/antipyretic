class PDF::Reader
  def each_line
    pages.each do |page|
      page.text.each_line do |line|
        yield line
      end
    end
  end

  def any_line?
    each_line do |line|
      return true if yield line
    end
  end

  def first_line
    value = nil
    each_line do |line|
      value = yield line
      break if value
    end
    value
  end
end