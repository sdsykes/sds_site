#  thETA interpreter  S.D.Sykes
#  v1.0    9th May 2001
#  v1.1    22 July 2001 Added exceptions for bad transfers and out of range chars on output
#  v2.0    15 Feb  2002 Made into first thETA threaded ETA interpreter

$Debug = false  # allows z instruction to print stack

class ETA
  attr :curline
  def initialize(startline,startstack)
    @stack= Array.new
    @stack += startstack
    @curline= startline
    @curnumber= 0
    @children = Array.new
    def @stack.pop
      p= super
      raise if p.nil?
      p
    end
  end

  def eachnextline
    while @curline < $prog.size.next && @curline > 0
      @nextline= @curline.next
      prevline = @curline
      yield @curline
      @curline= @nextline
    end
    if (@children.size > 0)
      Thread.current["children"]=@children
    end
    if (@curline > $prog.size.next || @curline < 0)
      raise TransferError.new(prevline)
    end
  end

  def eachchar(lineno)
    $prog[lineno-1].each_byte {|c| yield c.chr.downcase if lineno == @curline}
  end
  
  def e
    a= @stack.pop
    b= @stack.pop
    if (a==0)
      Thread.current["value"]=b
      Thread.current["children"]=@children
      Thread.exit
    end
    @stack.push b/a
    @stack.push b%a
  end
  
  def a
    @stack.push(@nextline)
  end

  def s
    a= @stack.pop
    b= @stack.pop
    @stack.push(b-a)
  end

  def i
    a= $stdin.getc
    a= -1 if a.nil?
    @stack.push(a)
  end

  def h
    a= @stack.pop
    p "a=#{a} stack=#{@stack.size}\n" if a.abs.next > @stack.size
    raise if a.abs.next > @stack.size
    if a > 0
      @stack.push(@stack[-a-1])
      @stack.delete_at(-a-2)
    else
      @stack.push(@stack[a-1])
    end
  end
  
  def o
    o= @stack.pop
    if (o < 256 && o >= 0)
      print o.chr
      $stdout.flush
    elsif (o < 0)
      done = 0
      Thread.current.priority = -5    # wait runs at low priority
      while (@children.size > 0 && done < -o)
        ch = Array.new
        ch += @children
        ch.each {|c|
          if (!c.status)  # is dead
            if (c.key?("value"))
              c.join
              @stack.push c["value"]
              @children += c["children"]
              done += 1
              @children -= Array.new(1,c)
              break if done == -o
            elsif (c.key?("children")) # was dead but no value so collect children
              @children += c["children"]
              c.join
              @children -= Array.new(1,c)
            else    # something else happened to the thread
              c.join
              @children -= Array.new(1,c)
            end
          end
        }
        if (done < -o && @children.size > 0)
          sleep 0.25
        end
      end
      @stack.push(done)
      Thread.current.priority = 0
    else
      raise OutputError
    end
  end

  def t
     a= @stack.pop
     if @stack.pop.nonzero?
       if (a>=0) # positive transfer works in the old way
         @nextline= a
         @curline= 0
       else
         @children << makeNewThread(-a, @stack)
       end
     end
  end

  def z
    p @stack if $Debug  # debugging help
  end

  def n
    def self.send(c)
      if c == "e"
        @stack.push(@curnumber)
        @curnumber= 0
        class <<self
          remove_method :send
        end
      else
        @curnumber= @curnumber * 7 + ["h","t","a","o","i","n","s"].index(c) if c != "z"
      end
    end
  end
end

class OutputError < Exception
end
class TransferError < Exception
  attr_reader :prevline
  def initialize(pl)
    @prevline = pl
  end
end

def makeNewThread(sl,ss)
  priv_ss = Array.new
  priv_ss += ss  # careful to get a clean copy of the stack to pass
  Thread.new(sl,priv_ss) {|sl,ss|
    begin
      p=ETA.new(sl,ss)
      p.eachnextline do |lineno|
        p.eachchar(lineno) {|c| p.send(c) if c=~ /e|t|a|o|n|i|s|h|z/}
      end
    rescue OutputError
      $stderr.print "Output char out of range at line #{p.curline}\n"
    rescue TransferError => te
      $stderr.print "Transfer error: non existent line #{p.curline} from line #{te.prevline}\n"
    rescue RuntimeError
      $stderr.print "Stack underflow at line #{p.curline}\n"
    rescue Interrupt
      $stderr.print "Interrupted at line #{p.curline}\n"
    end
  }
end

$prog= $<.readlines

Thread.abort_on_exception = true
makeNewThread(1,[])

Thread.current.priority = -10
while(true)
  running=0
  Thread.list.each {|t|
    if (t.status)
      running += 1
    end
  }
  if (running == 1)
    break;
  end
  sleep 1
end
