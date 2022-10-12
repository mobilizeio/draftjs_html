RSpec::Matchers.define :eq_ignoring_whitespace do |expected|
  match do |actual|
    @actual = actual.gsub(/[[:space:]]/, '')
    @expected_as_array = [expected.gsub(/[[:space:]]/, '')]

    values_match?(@expected_as_array.first, @actual)
  end

  diffable
end