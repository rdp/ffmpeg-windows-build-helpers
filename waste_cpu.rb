raise 'need jruby since it uses threads currently' unless RUBY_DESCRIPTION =~ /jruby/
threads = 5
puts "ctrl+c to stop, using #{threads} threads"
threads.times { Thread.new { loop {} } }
sleep