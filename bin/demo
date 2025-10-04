#!/usr/bin/env ruby

require 'fileutils'
require 'open3'
require 'rainbow/refinement'
require_relative '../lib/highline_wrappers'

using Rainbow

module NugemDemo
  def self.run(command, input)
    shell = HighLine.new
    shell.say command.yellow
    Open3.popen3(command) do |stdin, stdout, stderr, thread|
      Thread.new do
        input.split("\n").each { |line| stdin.puts line }
      end

      stdout.each_line { |line| puts line }

      Thread.new do
        until (line = stderr.gets).nil?
          yield nil, line, thread
        end
      end

      thread.join
    end
  end

  class Demo
    include HighlineWrappers

    def initialize
      # FileUtils.rm_rf 'demo'

      @shell = HighLine.new

      gem_type = ARGV[0] || 'jekyll'
      @gem_type = @shell.ask('Type of gem to test: '.green) do |q|
        q.default = gem_type
        q.default_hint_show = true
        q.validate = /^(ruby|jekyll)$/i
      end
      puts "@gem_type=#{@gem_type}"

      @gem_name = ARGV[1] || @shell.ask('Name of the gem: '.green) do |q|
        q.default = 'test'
        q.default_hint_show = true
      end

      case @gem_type
      when 'ruby'
        ruby_info

      when 'jekyll'
        jekyll_info
      end
    end

    def jekyll_info
      @jekyll_type = @shell.ask 'Type of Jekyll plugin: ', default: 'tag', limited_to: %w[block tag filter]
      loop do
        @jekyll_name = @shell.ask "#{@jekyll_type.capitalize} name: "
        break unless @jekyll_name.empty?
      end
      @jekyll_parameter_names = @shell.ask('Jekyll parameter names: ').split(/[, ]/)
      @jekyll_parameter_types = @jekyll_parameter_names.map do |name|
        @shell.ask "#{name} type", default: 'string', limited_to: %w[string numeric]
      end
      input = <<~END_INFO
        #{@jekyll_parameter_names.join ' '}
        #{@jekyll_parameter_types.join "\n"}
        no
      END_INFO
      NugemDemo.run "exe/nugem #{@gem_type} #{@gem_name} --#{@jekyll_type} #{@jekyll_name}", input
    end

    def ruby_info
      NugemDemo.run 'exe/nugem', "#{@gem_type} #{@gem_name}"
    end
  end

  Demo.new
end
