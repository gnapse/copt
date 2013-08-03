require 'copt'

class SampleApp
  include Copt

  def self.reset
    super

    app 'Sample app', version: '0.0.1', help: true

    cmd :show, 'Shows the requested item' do
      opt :ignore_cache, 'Ignores cached contents', short: 'r'
      opt :pager, 'Shows item contents in a pager', short: 'p'
      opt :summary, 'Shows only a summary of the contents', short: 's'
      run { _puts 'Showing...' }
    end

    cmd :list, 'Lists all items' do
      opt :sorted, 'Sorts the listed items by name', short: 's'
      check('This command expects no arguments') { args.empty? }
      run { _puts 'Listing...' }
    end

    cmd :complex, 'Complex command' do
      opt :dest, 'The destination folder', type: String, default: ENV['HOME']
      opt :num_lines, 'The number of lines to process', default: 0
      opt :since, 'The date where processing should start', type: Date
      opt :quiet, 'Do not print out any output'
      run { _puts opts }
    end

    self.footprint = 'Nothing'
  end

  def _puts(str)
    self.class.footprint = str
  end

  class << self
    attr_accessor :footprint
  end
end
