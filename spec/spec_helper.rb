ENV["RAILS_ENV"] ||= "test"

RSpec.configure do |config|
  # this should be replaced with #filter_run_when_matching in RSpec ~> v3.5.0
  # so we don't have to pollute inclusions with :focus on every rspec run
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
end
