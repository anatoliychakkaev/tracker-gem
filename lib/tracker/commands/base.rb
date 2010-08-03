require 'fileutils'

module Tracker::Command
  class Base
    include Tracker::Helpers

    attr_accessor :args
    attr_reader :autodetected_app
    def initialize(args, tracker=nil)
      @args = args
      @tracker = tracker
      @autodetected_prj = false
    end

    def confirm(message="Are you sure you wish to continue? (y/n)?")
      display("#{message} ", false)
      ask.downcase == 'y'
    end

    def format_date(date)
      date = Time.parse(date) if date.is_a?(String)
      date.strftime("%Y-%m-%d %H:%M %Z")
    end

    def ask
      gets.strip
    end

    def shell(cmd)
      FileUtils.cd(Dir.pwd) {|d| return `#{cmd}`}
    end

    def tracker
      @tracker ||= Tracker::Command.run_internal('auth:client', args)
    end

    def extract_project(force=true)
      prj = extract_option('--prj')
      unless prj
        prj = extract_project_in_dir(Dir.pwd) ||
        raise(CommandFailed, "No project specified.\nRun this command from app folder or set it adding --prj <project id>") if force
        @autodetected_prj = true
      end
      prj
    end

    def extract_project_in_dir(dir)
      File.read("#{dir}/.tracker").to_i
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end

    def escape(value)
      tracker.escape(value)
    end
  end

  class BaseWithProject < Base
    attr_accessor :project

    def initialize(args, tracker=nil)
      super(args, tracker)
      @project ||= extract_project
    end
  end
end
