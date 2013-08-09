class MatchData
  def pretty_print
    result = [self[0]]
    (1..(length - 1)).each do |i|
      result << "#{i.to_s.rjust(4)}: #{self[i]}"
    end
    result.join("\n")
  end
end