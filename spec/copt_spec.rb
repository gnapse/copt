require 'spec_helper'
require 'copt'

class TestApp
  include Copt

  def self.reset
    super

    app 'Test app', version: '0.0.1', help: true

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

describe Copt do
  before(:each) { TestApp.reset }

  let(:commands) { TestApp.send :commands }
  let(:current_command) { TestApp.instance_variable_get(:@command) }

  def expect_failure(&block)
    expect(&block).to change(TestApp.errors, :size).by(1)
  end

  def expect_success(&block)
    expect(&block).not_to change(TestApp.errors, :size)
  end

  def command_context
    TestApp.command(:edit, 'desc') do
      yield
      TestApp.run {}
    end
  end

  describe '.app' do
    it "defines the app's description" do
      expect(TestApp.description).to eq('Test app')
    end

    it "defines the app's version number" do
      expect(TestApp.version).to eq('0.0.1')
    end

    it "defines the app's configuration settings" do
      expect(TestApp.config.keys).to eq([:version, :help])
    end
  end

  describe '.command' do
    it "defines a new command" do
      expect {
        TestApp.command(:edit, 'desc') { TestApp.run {} }
      }.to change(commands, :length).by(1)
    end

    it "fails in case of duplicate command name" do
      expect_failure do
        TestApp.command(:show, 'description') { TestApp.run {} }
      end
    end

    it "fails if no execution block is defined for the command" do
      expect_failure do
        TestApp.command(:edit, 'desc') {}
      end
    end
  end

  describe '.option' do
    it "defines a new option for the current command" do
      command_context do
        expect { TestApp.option :name, 'desc' }.to change(current_command.options, :size).by(1)
      end
    end

    it "fails in case of duplicate option keys" do
      command_context do
        expect_success { TestApp.option :name, 'description', short: 'n', long: 'long' }
        expect_failure { TestApp.option :none, 'description', short: 'n' }
        expect_failure { TestApp.option :name, 'description' }
        expect_failure { TestApp.option :long, 'description' }
      end
    end

    it "fails when option keys are invalid" do
      command_context do
        expect_failure { TestApp.option :n, 'description' }
        expect_failure { TestApp.option :one, 'description', short: 'long' }
        expect_failure { TestApp.option :two, 'description', long: 's' }
      end
    end
  end

  describe '.check' do
    it 'sets a condition that must be checked upon execution of the command' do
      command_context do
        expect { TestApp.check('Message') { true } }.to change(current_command.preconditions, :size).by(1)
      end
    end

    it 'fails if a block is not provided' do
      command_context do
        expect_failure { TestApp.check('Message') }
      end
    end
  end

  describe '.run' do
    it "defines the block of code to execute for the current command" do
      TestApp.command :edit, 'desc' do
        expect(current_command.block).to be_nil
        TestApp.run {}
        expect(current_command.block).not_to be_nil
      end
    end

    it "does not allow to be called more than once per command" do
      TestApp.command :edit, 'description' do
        expect_success { TestApp.run {} }
        expect_failure { TestApp.run {} }
      end
    end
  end

  describe '.run!' do
    it "recognizes options and arguments passed on the command line" do
      app = TestApp.run! %w(show one --ignore-cache two three -ps)
      expect(app.args).to eq(%w(one two three))
      expect(app.opts).to eq(pager: true, summary: true, ignore_cache: true)
    end

    it "recognizes the '--' argument marker properly" do
      app = TestApp.run! %w(show one --pager -- two three -rs)
      expect(app.args).to eq(%w(one two three -rs))
      expect(app.opts).to eq({pager: true})
    end

    it "recognizes the specified subcommand and invokes the appropriate block" do
      app = TestApp.run! %w(show)
      expect(app.command).to eq(:show)
      expect(TestApp.footprint).to eq('Showing...')

      app = TestApp.run! %w(list)
      expect(app.command).to eq(:list)
      expect(TestApp.footprint).to eq('Listing...')
    end

    it "checks all the subcommand's preconditions, if any" do
      expect { TestApp.run! %w(list hello) }.to raise_error(SystemExit)
    end

    context "when invoked with the --help option" do
      it "bypasses execution and prints the help message" do
        expect { TestApp.run! %w(list --help) }.to raise_error(SystemExit)
        expect(TestApp.footprint).not_to eq('Listing...')
      end
    end

    context "when invoked with an invalid subcommand name" do
      it "should fail execution and exit" do
        expect { TestApp.run! %w(edit) }.to raise_error(SystemExit)
      end
    end

    context "when invoked with invalid options" do
      it "should fail execution and exit" do
        expect { TestApp.run! %w(show --all) }.to raise_error(SystemExit)
        expect(TestApp.footprint).not_to eq('Showing...')
      end
    end
  end
end
