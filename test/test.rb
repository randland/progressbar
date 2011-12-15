require 'test/unit'
require 'progressbar'

class ProgressBarTest < Test::Unit::TestCase
  SleepUnit = 0.01

  def do_make_progress_bar (title, total, opts = {})
    ProgressBar.new(title, total, opts)
  end

  def test_bytes
    total = 1024 * 1024
    pbar = do_make_progress_bar("test(bytes)", total)
    pbar.file_transfer_mode
    0.step(total, 2**14) {|x|
      sleep(SleepUnit)
      pbar.set(x)
    }
    pbar.finish
  end

  def test_clear
    total = 100
    pbar = do_make_progress_bar("test(clear)", total)
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.clear
    puts
  end

  def test_columns
    total = 100
    pbar = do_make_progress_bar("test(columns)", total, columns: 60)
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.finish
  end

  def test_custom_bar_mark
    total = 100
    pbar = do_make_progress_bar("test(custom)", total)
    pbar.bar_mark = '='
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.finish
  end

  def test_custom_bar_mark_on_init
    total = 100
    pbar = do_make_progress_bar("test(init)", total, bar_mark: '=')
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.finish
  end

  def test_globals
    total = 100
    ProgressBar.columns = 60
    pbar = do_make_progress_bar("test(globals)", total)
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.finish
    ProgressBar.clear_globals
  end

  def test_halt
    total = 100
    pbar = do_make_progress_bar("test(halt)", total)
    (total / 2).times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.halt
  end

  def test_inc
    total = 100
    pbar = do_make_progress_bar("test(inc)", total)
    total.times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.finish
  end

  def test_inc_x
    total = File.size("lib/progressbar.rb")
    pbar = do_make_progress_bar("test(inc(x))", total)
    File.new("lib/progressbar.rb").each {|line|
      sleep(SleepUnit)
      pbar.inc(line.length)
    }
    pbar.finish
  end

  def test_invalid_set
    total = 100
    pbar = do_make_progress_bar("test(invalid set)", total)
    begin
      pbar.set(200)
    rescue RuntimeError => e
      puts e.message
    end
  end

  def test_iter_rate_mode
    total = 100
    pbar = do_make_progress_bar("test(iter rate)", total)
    pbar.iter_rate_mode
    total.times do
      sleep(SleepUnit)
      pbar.inc
    end
    pbar.finish
  end

  def test_iter_rate_mode_slow
    total = 3
    pbar = do_make_progress_bar("test(iter slow)", total)
    pbar.iter_rate_mode
    total.times do
      sleep(1.1)
      pbar.inc
    end
    pbar.finish
  end

  def test_remaining
    chunk = 100
    pbar = do_make_progress_bar('test(remaining)', chunk)
    pbar.inc
    3.times do
      (chunk - 10).times do
        pbar.inc
        sleep(SleepUnit)
      end
      pbar.remaining = chunk
    end
    chunk.times do
      pbar.inc
      sleep(SleepUnit)
    end
    pbar.finish
  end

  def test_set
    total = 1000
    pbar = do_make_progress_bar("test(set)", total)
    (1..total).find_all {|x| x % 10 == 0}.each {|x|
      sleep(SleepUnit)
      pbar.set(x)
    }
    pbar.finish
  end

  def test_slow
    total = 100000
    pbar = do_make_progress_bar("test(slow)", total)
    0.step(300, 1) {|x|
      sleep(SleepUnit)
      pbar.set(x)
    }
    pbar.halt
  end

  def test_status
    total = 150
    pbar = do_make_progress_bar("test(status)", total)
    pbar.show_colored_status
    (total / 3).times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.warning
    (total / 3).times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.error
    (total / 3).times {
      sleep(SleepUnit)
      pbar.inc
    }
    pbar.reset_status
    pbar.finish
  end

  def test_title
    total = 100
    pbar = do_make_progress_bar('test(title)', total)
    total.times {|i|
      sleep(SleepUnit)
      pbar.inc
      pbar.title = "test(#{i + 1})"
    }
    pbar.finish
  end

  def test_total
    total = 100
    pbar = do_make_progress_bar('test(total)', total)
    pbar.inc
    total.step(1, -1) {|x|
      sleep(SleepUnit)
      pbar.total = x
    }
    pbar.finish
  end

  def test_total_zero
    total = 0
    pbar = do_make_progress_bar("test(total=0)", total)
    pbar.finish
  end

end

class ReversedProgressBarTest < ProgressBarTest
  def do_make_progress_bar (title, total, opts = {})
    ReversedProgressBar.new(title, total, opts)
  end
end
