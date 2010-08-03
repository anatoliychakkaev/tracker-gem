require 'tracker/tracker_helper'
require 'tracker/commands/base'

Dir["#{File.dirname(__FILE__)}/commands/*"].each { |c| require c }

module Tracker
  class CommandNotFound < RuntimeError; end

  extend Tracker::Helpers

  module Command 
    class << self
      def run(command_str, args, try_number=0)
        run_internal "auth:authorize", args if try_number > 0
        run_internal command_str, args
      end

      def run_internal(cmd, args)
        commandor_class, command = parse(cmd)
        commandor = commandor_class.new(args)
        raise CommandNotFound, "No command #{command} in class #{commandor_class}" unless commandor.respond_to? command
        commandor.send command
      end

      def parse(command)
        token = command.split ':'
        if token.size == 1
          begin
            return eval("Tracker::Command::#{command.capitalize}"), :main
          rescue NameError, NoMethodError
            return Tracker::Command::Application, command
          end
        else
          begin
            return Tracker::Command.const_get(token.first.capitalize), token.last
          rescue NameError
            raise CommandNotFound
          end
        end
      end
    end
  end
end
