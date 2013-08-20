require 'copt'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Disallow using the 'should' syntax.
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Suppress stderr and stdout output during tests
  config.before :all do
    # Redirects stderr and stdout to /dev/null.
    @orig_stderr = $stderr
    @orig_stdout = $stdout
    $stderr = File.new('/dev/null', 'w')
    $stdout = File.new('/dev/null', 'w')
  end

  # Restore stderr and stdout after tests
  config.after :all do
    $stderr = @orig_stderr
    $stdout = @orig_stdout
    @orig_stderr = nil
    @orig_stdout = nil
  end
end
