require 'spec_helper'
require 'sample_app'

describe Copt::App do
  before(:each) { SampleApp.reset }

  let(:commands) { SampleApp.send :commands }
  let(:current_command) { SampleApp.instance_variable_get(:@command) }

  def expect_failure(&block)
    expect(&block).to change(SampleApp.errors, :size).by(1)
  end

  def expect_success(&block)
    expect(&block).not_to change(SampleApp.errors, :size)
  end

  def command_context
    SampleApp.command(:edit, 'desc') do
      yield
      SampleApp.run {}
    end
  end

  describe '.app' do
    it "defines the app's description" do
      expect(SampleApp.description).to eq('Sample app')
    end

    it "defines the app's version number" do
      expect(SampleApp.version).to eq('0.0.1')
    end

    it "defines the app's configuration settings" do
      expect(SampleApp.config.keys).to eq([:version, :help])
    end
  end

  describe '.command' do
    it "defines a new command" do
      expect {
        SampleApp.command(:edit, 'desc') { SampleApp.run {} }
      }.to change(commands, :length).by(1)
    end

    it "fails in case of duplicate command name" do
      expect_failure do
        SampleApp.command(:show, 'description') { SampleApp.run {} }
      end
    end

    it "fails if no execution block is defined for the command" do
      expect_failure do
        SampleApp.command(:edit, 'desc') {}
      end
    end
  end

  describe '.option' do
    it "defines a new option for the current command" do
      command_context do
        expect { SampleApp.option :name, 'desc' }.to change(current_command.options, :size).by(1)
      end
    end

    it "fails in case of duplicate option keys" do
      command_context do
        expect_success { SampleApp.option :name, 'description', short: 'n', long: 'long' }
        expect_failure { SampleApp.option :none, 'description', short: 'n' }
        expect_failure { SampleApp.option :name, 'description' }
        expect_failure { SampleApp.option :long, 'description' }
      end
    end

    it "fails when option keys are invalid" do
      command_context do
        expect_failure { SampleApp.option :n, 'description' }
        expect_failure { SampleApp.option :one, 'description', short: 'long' }
        expect_failure { SampleApp.option :two, 'description', long: 's' }
      end
    end
  end

  describe '.check' do
    it 'sets a condition that must be checked upon execution of the command' do
      command_context do
        expect { SampleApp.check('Message') { true } }.to change(current_command.preconditions, :size).by(1)
      end
    end

    it 'fails if a block is not provided' do
      command_context do
        expect_failure { SampleApp.check('Message') }
      end
    end
  end

  describe '.run' do
    it "defines the block of code to execute for the current command" do
      SampleApp.command :edit, 'desc' do
        expect(current_command.block).to be_nil
        SampleApp.run {}
        expect(current_command.block).not_to be_nil
      end
    end

    it "does not allow to be called more than once per command" do
      SampleApp.command :edit, 'description' do
        expect_success { SampleApp.run {} }
        expect_failure { SampleApp.run {} }
      end
    end
  end

  describe '.run!' do
    it "recognizes options and arguments passed on the command line" do
      app = SampleApp.run! %w(show one --ignore-cache two three -ps)
      expect(app.args).to eq(%w(one two three))
      expect(app.opts).to eq(pager: true, summary: true, ignore_cache: true)
    end

    it "recognizes the '--' argument marker properly" do
      app = SampleApp.run! %w(show one --pager -- two three -rs)
      expect(app.args).to eq(%w(one two three -rs))
      expect(app.opts).to eq({pager: true})
    end

    it "recognizes the specified subcommand and invokes the appropriate block" do
      app = SampleApp.run! %w(show)
      expect(app.command).to eq(:show)
      expect(SampleApp.footprint).to eq('Showing...')

      app = SampleApp.run! %w(list)
      expect(app.command).to eq(:list)
      expect(SampleApp.footprint).to eq('Listing...')
    end

    it "checks all the subcommand's preconditions, if any" do
      expect { SampleApp.run! %w(list hello) }.to raise_error(SystemExit)
    end

    context "when invoked with the --help option" do
      it "bypasses execution and prints the help message" do
        expect { SampleApp.run! %w(list --help) }.to raise_error(SystemExit)
        expect(SampleApp.footprint).not_to eq('Listing...')
      end
    end

    context "when invoked with an invalid subcommand name" do
      it "should fail execution and exit" do
        expect { SampleApp.run! %w(edit) }.to raise_error(SystemExit)
      end
    end

    context "when invoked with invalid options" do
      it "should fail execution and exit" do
        expect { SampleApp.run! %w(show --all) }.to raise_error(SystemExit)
        expect(SampleApp.footprint).not_to eq('Showing...')
      end
    end
  end

  describe "nested subcommand invocation" do
    def nested_caller(name = :nest, &block)
      SampleApp.cmd(name, 'Calls other commands') { SampleApp.run(&block) }
    end

    it "works" do
      nested_caller { run(:show) }
      SampleApp.run! %w(nest)
      expect(SampleApp.footprint).to eq('Showing...')
    end

    it "allows to provide different arguments and options to the invoked command" do
      # The nested subcommand is instructed to skip error checks, so it won't fail.
      nested_caller(:nest1) { run(:list, check: false) }
      SampleApp.run! %w(nest1 one two three)
      expect(SampleApp.footprint).to eq('Listing...')
      SampleApp.footprint = nil

      # The nested subcommand is explicitly given no arguments, so it won't fail.
      nested_caller(:nest2) { run(:list, args: []) }
      SampleApp.run! %w(nest2 one two three)
      expect(SampleApp.footprint).to eq('Listing...')
      SampleApp.footprint = nil

      # The nested subcommand refuses to receive arguments so it fails
      nested_caller(:nest3) { run(:list) }
      expect { SampleApp.run! %w(nest3 one two three) }.to raise_error(SystemExit)
      expect(SampleApp.footprint).not_to eq('Listing...')
      SampleApp.footprint = nil
    end
  end
end
