#  ETA interpreter  S.D.Sykes
#  v1.0    9th May 2001
#  v1.1    22 July 2001 Added exceptions for bad transfers and out of range chars on output
#  v1.2    30 Oct  2003 Changed % to remainder to match ref interpreter results for negative modulos

class ETA
  attr :curline
  def initialize
    @stack= Array.new
    @prog= $<.readlines
    @curline= 1
    @curnumber= 0
    def @stack.pop
      p= super
      raise if p.nil?
      p
    end
  end

  def eachnextline
    while @curline < @prog.size.next && @curline > 0
      @nextline= @curline.next
      prevline = @curline
      yield @curline
      @curline= @nextline
    end
    if (@curline > @prog.size.next || @curline < 0)
      raise TransferError.new(prevline)
    end
  end

  def eachchar(lineno)
    @prog[lineno-1].each_byte {|c| yield c.chr.downcase if lineno == @curline}
  end
  
  def e
    a= @stack.pop
    b= @stack.pop
    @stack.push b/a
    @stack.push b.remainder(a)
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
    else
      raise OutputError
    end
  end

  def t
     a= @stack.pop
     if @stack.pop.nonzero?
       @nextline= a
       @curline= 0
     end
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
        @curnumber= @curnumber * 7 + ["h","t","a","o","i","n","s"].index(c)
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

begin
  p=ETA.new
  p.eachnextline do |lineno|
    p.eachchar(lineno) {|c| p.send(c) if c=~ /e|t|a|o|n|i|s|h/}
  end
rescue OutputError
  $stderr.print "Output char out of range at line #{p.curline}\n"
rescue TransferError => te
  $stderr.print "Transfer error: non existent line #{p.curline} from line #{te.prevline}\n"
rescue RuntimeError
  $stderr.print "Stack underflow at line #{p.curline}\n"
rescue ZeroDivisionError
  $stderr.print "Division by zero at line #{p.curline}\n"
rescue Interrupt
  $stderr.print "Interrupted at line #{p.curline}\n"
end
