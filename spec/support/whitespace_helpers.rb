RSpec::Matchers.define :eq_ignoring_whitespace do |expected|
  match do |actual|
    @actual = actual.gsub(/[[:space:]]/, '')
    @expected = expected.gsub(/[[:space:]]/, '')
    @expected_as_array = [@expected]

    values_match?(@expected_as_array.first, @actual)
  end

  diffable

  failure_message do |actual|
    message = "expected that #{actual} would match #{@expected}"
    message += "\nDiff:" + differ.diff_as_string(actual, @expected)
    message
  end

  def differ
    RSpec::Support::Differ.new(
      :object_preparer => lambda { |object| RSpec::Matchers::Composable.surface_descriptions_in(object) },
      :color => RSpec::Matchers.configuration.color?
    )
  end
end
