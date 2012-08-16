raise 'need jruby since it uses threads currently' unless RUBY_DESCRIPTION =~ /jruby/
threads = (ARGV[0] || "5").to_i
puts "ctrl+c to stop, using #{threads} threads"
threads.times { Thread.new { loop {} } }
sleep