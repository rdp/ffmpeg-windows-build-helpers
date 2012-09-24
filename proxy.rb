require 'socket'
#require 'tracer'
 a = TCPServer.new '127.0.0.1', 1935
puts a
require 'rubygems'
require 'sane'
#require 'ruby-debug'
#Tracer.on
while(got=a.accept)
  p 'GOT ONE'
  Thread.new(got){|got2|
    outgoing = TCPSocket.new '10.88.44.186', 1936
    while(true)
      #debugger
      r,w,e=IO.select([got2, outgoing], nil, nil)
      if r.contain? got2
        _,w,e = IO.select(nil, [outgoing], nil, 0)
        $stdout.print '.'

        if w == [outgoing]
          $stdout.print '+'
          gotty = got2.recv 1024
		  sleep 0.1
          outgoing.write gotty # TODO send instead of write...
        end
      end
      if r.contain? outgoing
        _,w,e = IO.select(nil, [got2], nil, 0)
        $stdout.print ','
        if w == [got2]
          $stdout.print '-'
		  sleep 0.1
          got2.write outgoing.recv(1024)
        end        
      end
    end
  }
  

end