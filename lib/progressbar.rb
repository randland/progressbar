#
# Ruby/ProgressBar - a text progress bar library
#
# Copyright (C) 2001-2005 Satoru Takabayashi <satoru@namazu.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms
# of Ruby's license.
#
require 'colorful'

class ProgressBar
  VERSION = "0.9"
  @@_defaults ||= {title_width: 14}

  def self.method_missing method, *args, &blk
    if method.to_s.match(/=$/)
      @@_defaults[method.to_s.sub(/=$/,'').to_sym] = args[0]
    else
      super
    end
  end

  def self.clear_globals
    @@_defaults = {}
  end

  def self.default_title_width
    @@_defaults[:title_width]
  end

  def self.default_format *args
    args ||= [default_title_width]
    "%-#{args[0]}s %3d%% %s %s"
  end

  def self.disable_output
    @@_defaults[:output_disabled] = true
  end

  def self.enable_output
    @@_defaults[:output_disabled] = false
  end

  def self.iter_rate_mode
    @@_defaults[:iter_rate_mode] = true
  end

  def self.file_transfer_mode
    @@_defaults[:file_transfer_mode] = true
  end

  def self.color_status
    @@_defaults[:color_status] = true
  end

  attr_reader   :title
  attr_reader   :current
  attr_reader   :total
  attr_reader   :status
  attr_accessor :start_time
  attr_writer   :bar_mark

  def initialize (title, total, opts = {})
    if opts.respond_to? :print
      opts = { out: opts }
    end

    defaults = { bar_mark: '=',
                 out: STDERR,
                 current: 0,
                 format_arguments:  [:title, :percentage, :bar, :stat],
                 terminal_width: 80,
                 title_width: [self.class.default_title_width, title.size + 1].max }
    defaults.merge(@@_defaults).merge(opts).each do |attr, val|
      instance_variable_set("@#{attr}", val)
    end
    @title = title
    @total = total
    @finished_p = false
    @title_width = self.class.default_title_width unless @expand_title
    @format ||= self.class.default_format @title_width
    @previous = @current
    @start_time = @previous_time = Time.now
    clear
    iter_rate_mode if @@_defaults[:iter_rate_mode]
    file_transfer_mode if @@_defaults[:file_transfer_mode]
    color_status if @@_defaults[:color_status]
    show
  end

  def clear
    output "\r"
    output(" " * (get_term_width - 1))
    output "\r"
  end

  def finish
    @current = @total
    @end_time = Time.now
    @finished_p = true
    show
  end

  def rate
    ((@end_time || Time.now) - @start_time).seconds / @current.to_f
  end

  def finished?
    @finished_p
  end

  def file_transfer_mode
    @format_arguments = [:title, :percentage, :bar, :stat_for_file_transfer]
    show
  end

  def iter_rate_mode
    @format_arguments = [:title, :percentage, :bar, :stat_for_iter_rate]
    show
  end

  def format= (format)
    @format = format
    show
  end

  def format_arguments= (arguments)
    @format_arguments = arguments
    show
  end

  def halt
    @finished_p = true
    show
  end

  def inc (step = 1)
    @current += step
    @current = @total if @current > @total
    show_if_needed
    @previous = @current
  end

  def set (count)
    if count < 0 || count > @total
      raise "invalid count: #{count} (total: #{@total})"
    end
    @current = count
    show_if_needed
    @previous = @current
  end

  def inspect
    "#<ProgressBar:#{@current}/#{@total}>"
  end

  def title= val
    @title = val
    show
  end

  def total= val
    @total = val
    show
  end

  def remaining= val
    self.total = @current + val
  end

  def color_status
    @status ||= :green
    show_if_needed
  end

  def colorize color
    @status = color.to_sym
    show_if_needed
  end

  def hide_color_status
    @status = nil
    show_if_needed
  end

  def reset_status
    colorize :green
  end

  def warning
    colorize(:yellow) unless @status == :red
  end

  def error
    colorize :red
  end

  def expand_title
    @expand_title = true
    @title_width = title.size + 1
    @format = self.class.default_format
    show
  end

private

  def output str
    @out.print str unless @@_defaults[:output_disabled]
  end

  def flush
    @out.flush unless @@_defaults[:output_disabled]
  end

  def fmt_bar
    bar_width = (do_percentage * @terminal_width / 100).to_i
    sprintf("|%s%s|",
            @bar_mark * bar_width,
            " " *  (@terminal_width - bar_width))
  end

  def fmt_percentage
    do_percentage
  end

  def fmt_stat
    if @finished_p then elapsed else eta end
  end

  def fmt_stat_for_file_transfer
    if @finished_p then
      sprintf("%s %s %s", bytes, transfer_rate, elapsed)
    else
      sprintf("%s %s %s", bytes, transfer_rate, eta)
    end
  end

  def fmt_stat_for_iter_rate
    if @finished_p then
      sprintf("%s %s", iter_rate, elapsed)
    else
      sprintf("%s %s", iter_rate, eta)
    end
  end

  def fmt_title
    @title[0,(@title_width - 1)] + ":"
  end

  def convert_bytes (bytes)
    if bytes < 1024
      sprintf("%6dB", bytes)
    elsif bytes < 1024 * 1000 # 1000kb
      sprintf("%5.1fKB", bytes.to_f / 1024)
    elsif bytes < 1024 * 1024 * 1000  # 1000mb
      sprintf("%5.1fMB", bytes.to_f / 1024 / 1024)
    else
      sprintf("%5.1fGB", bytes.to_f / 1024 / 1024 / 1024)
    end
  end

  def transfer_rate
    bytes_per_second = @current.to_f / (Time.now - @start_time)
    sprintf("%s/s |", convert_bytes(bytes_per_second))
  end

  def bytes
    convert_bytes(@current)
  end

  def iter_rate
    iter_per_second = @current.to_f / (Time.now - @start_time)
    if iter_per_second > 1
      sprintf("%8.2f/s |", iter_per_second)
    else
      sprintf("%6.2fs ea |", 1 / iter_per_second)
    end
  end

  def format_time (t)
    t = t.to_i
    sec = t % 60
    min  = (t / 60) % 60
    hour = t / 3600
    sprintf("%02d:%02d:%02d", hour, min, sec);
  end

  # ETA stands for Estimated Time of Arrival.
  def eta
    if @current == 0
      "ETA:  --:--:--"
    else
      elapsed = Time.now - @start_time
      eta = elapsed * @total / @current - elapsed;
      sprintf("ETA:  %s", format_time(eta))
    end
  end

  def elapsed
    elapsed = Time.now - @start_time
    sprintf("Time: %s", format_time(elapsed))
  end

  def eol
    if @finished_p then "\n" else "\r" end
  end

  def do_percentage
    if @total.zero?
      100
    else
      @current  * 100 / @total
    end
  end

  DEFAULT_WIDTH = 80
  def get_term_width
    if ENV['COLUMNS'] =~ /^\d+$/
      ENV['COLUMNS'].to_i
    elsif @columns
      @columns
    elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && shell_command_exists?('tput')
      `tput cols`.to_i
    elsif STDIN.tty? && shell_command_exists?('stty')
      `stty size`.scan(/\d+/).map { |s| s.to_i }[1]
    else
      DEFAULT_WIDTH
    end
  rescue
    DEFAULT_WIDTH
  end

  def shell_command_exists?(command)
    ENV['PATH'].split(File::PATH_SEPARATOR).any?{|d| File.exists? File.join(d, command) }
  end

  def show
    arguments = @format_arguments.map {|method|
      method = sprintf("fmt_%s", method)
      send(method)
    }
    line = sprintf(@format, *arguments)

    width = get_term_width
    if line.length == width - 1
      output(line.send(@status || :to_s) + eol)
      flush
    elsif line.length >= width
      @terminal_width = [@terminal_width - (line.length - width + 1), 0].max
      if @terminal_width <= 0
        output(line.send(@status || :to_s) + eol)
      else
        show
      end
    else # line.length < width - 1
      @terminal_width += width - line.length + 1
      show
    end
    @previous_time = Time.now
  end

  def show_if_needed
    if @total.zero?
      cur_percentage = 100
      prev_percentage = 0
    else
      cur_percentage  = (@current  * 100 / @total).to_i
      prev_percentage = (@previous * 100 / @total).to_i
    end

    # Use "!=" instead of ">" to support negative changes
    if cur_percentage != prev_percentage ||
        Time.now - @previous_time >= 1 || @finished_p ||
        @previous_status != @status
      show
    end

    @previous_status = @status
  end
end

class ReversedProgressBar < ProgressBar
  def do_percentage
    100 - super
  end
end
