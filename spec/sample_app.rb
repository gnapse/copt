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

    self.footprint = 'Nothing'
  end

  def _puts(str)
    self.class.footprint = str
  end

  class << self
    attr_accessor :footprint
  end
end
