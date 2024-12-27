####################################################################
# Ruby thETA generator
#
# S.D.Sykes June 2001, Feb 2002
#
# User functions and classes
#
# class EtaInt, class InputBlock, class Table, class EtaArray
# eif, eelse, ewhile, eprint, eexit, input, input_number
# write, write_raw, next_line, finish
# forkif, threadreturn, threadcollect
#
####################################################################

require 'singleton'
$Debug = false
$MaxThreadCollect = 20

####################################################################
# Class EtaInt
# EtaInts can do arithmetic and comparisons, and know how to print
# themselves.
#
# They are signed 32 bit ints.
#
# Public methods: 
# -, +, /, %, *, <<, >>, - (unary), + (unary), &, |, ^, ~, ==, >=,
# <=, <, >, val, val=, delete, print, print_int
#
# Logical &&, || and ! are not overloadable.  So
# these cannot be used. However, != is allowed.  Although != is not 
# overloadable because the Ruby parser converts it to !(x==y), we get 
# around this by testing for false in the flow control functions, and 
# assuming that if we get false then we have been passed 
# !(EtaImmediate.instance). Then we just need to logically negate the 
# top stack var and continue.
#
####################################################################

class EtaInt
  attr_reader :slot  # slot in the stackarray

  def initialize(a = 0)
    if (a.integer?)
      @slot = ($s[self.to_s] = a)
      $p.write_comment("initialise-variable-to-#{a}")
    else
      @slot = ($s[self.to_s] = 0)
      $s[a.to_s] unless a.immediate?
      $s.set(self.to_s)
      $p.write_comment("initialise-variable")
    end
    $p.next_line
  end

  def integer?
    false
  end

  def immediate?
    false
  end

  def coerce (number)  # allows you to write expressions both ways round
    $p.write_num(number)
    [EtaImmediate.instance, self]
  end

  private
  def get_args (n)
    $s[self.to_s] unless immediate?
    if (n.integer?)
        $p.write_num(n)
    else
      if (n.immediate?)
        $p.write_literal("nte")
        $p.write_literal("h")
      else
        $s[n.to_s]
      end
    end
  end
  public

  def - (n)
    get_args(n)
    $p.write_literal("s")
    $p.write_comment("minus")
    $p.next_line
    EtaImmediate.instance
  end

  def + (n)
    get_args(n)
    $p.write_num(0)
    $p.write_literal("nte")
    $p.write_literal("h")
    $p.write_literal("s")
    $p.write_literal("s")
    $p.write_comment("plus")
    $p.next_line
    EtaImmediate.instance
  end

  def / (n)
    get_args(n)
    $p.write_literal("e")
    $p.write_chomp
    $p.write_comment("divide")
    $p.next_line
    EtaImmediate.instance
  end

  def % (n)
    get_args(n)
    $p.write_literal("e")
    $p.write_literal("nte")
    $p.write_literal("h")
    $p.write_chomp
    $p.write_comment("modulus")
    $p.next_line
    EtaImmediate.instance
  end

# This is the multiply algorithm (to multiply m by n)
#
# return zero if either arg is zero
# HI = 2 ** 31     # constant - for 32 bit signed ints 
# guess = HI / 2 
# increment = guess / 2 
# while true 
# z = guess/ n 
# if (z == m) 
#   print guess - (guess % n) 
#   exit 
# elsif (z < m) 
#   guess = guess + increment 
# else 
#   guess = guess - increment 
# end 
# increment = increment / 2 
# end

  def * (n)         # the code for multiply only gets written once, then can be called from elsewhere
    get_args(n)
    if (@multiply)
      $p.write_literal("a")    # save return address
      $p.write_literal("a")
      $p.write_num(@multiply)
      $p.write_literal("t")
      $p.write_comment("multiply-called")
      $p.next_line
      $p.stackdepth = $p.stackdepth - 2
      return EtaImmediate.instance
    else
      $p.write_num($p.linenumber + 21)  # return address is immediately after this function
      @multiply = $p.linenumber + 1
    end

    $p.next_line
    depth = $p.stackdepth
    $p.write_literal("naehnaeh")  # bury the return address

    $p.write_literal("neHat Hs aane") # test top arg for zero, set result to zero and jump to end if so
    $p.write_num(18)
    $p.write_literal("sst")
    $p.next_line
    $p.write_literal("nteh neHat Hs aane") # swap args and test for zero again
    $p.write_num(17)
    $p.write_literal("sst")
    $p.next_line

    $p.write_literal("ntenentesHne") # write 1 for flag on stack, then compare top arg with zero
    compare
    $p.write_literal("at")  # if less than zero, change sign of top arg, and change flag to 0
    $p.write_chomp
    $p.write_literal("nentehsne")
    $p.next_line
    $p.write_literal("nenaesHne") # compare 2nd from top arg with zero
    compare
    $p.write_literal("atntentehs")  # if less than zero change sense of flag (flag = 1 - flag)
    $p.write_literal("nenoehsnaehnaeh") # change sign of 2nd from top arg
    $p.next_line
    $p.write_literal("naehnaeh")  # bury the flag for later
    $p.write_num(1073741824)  # guess
    $p.write_num(536870912)   # increment
    $p.next_line              # stack is m n guess inc <top>
    $p.write_literal("nentesHnenoesH") # stack is now m n guess inc guess n <top>
    $p.write_literal("e")
    $p.write_chomp
    $p.write_literal("neHnennesH") # stack is now m n guess inc z z m <top>
    $p.write_literal("sat")  # goto next if not equal m n guess inc z <top>
    $p.write_literal("neHssneHssnaehneHss") # stack is now n guess <top>
    $p.write_literal("neHnaehentehneHsss")  # guess = guess - (guess % n)
    $p.write_literal("aanensesst")  # jump out
    $p.next_line
    $p.write_literal("neniesH")  # stack is now m n guess inc z m <top>
    compare
    $p.write_literal("atnenentesHsaanentesst") # jump to next if m < z, else stack now m n guess inc -inc, jump over next line
    $p.next_line
    $p.write_literal("neH") # stack is now m n guess inc inc
    $p.next_line
    $p.write_literal("nenaesHntehs") # stack is now m n guess inc newguess
    $p.write_literal("naeh") # stack is now m n inc newguess guess
    $p.write_chomp
    $p.write_literal("ntehnaee") # stack is now m n newguess inc/2 inc%2
    $p.write_chomp
    $p.write_literal("aanthest") # loop to a - 7
    $p.next_line
    $p.write_literal("ntehatnentehs")  # if flag was 0 then change sign of result
    $p.write_comment("multiply")
    $p.next_line
    $p.write_literal("ntehanteht")  # jump to return address
    $p.next_line
    $p.stackdepth = depth - 2
    EtaImmediate.instance
  end

  def << (n)  # left shift
    get_args(n)
    $p.next_line
    depth = $p.stackdepth
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.next_line
    $p.write_literal("ntehneHnentehssntehntesa")
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp n, which is now zero
    $p.write_comment("lshift")
    $p.next_line
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def >> (n)  # right shift
    get_args(n)
    $p.next_line
    depth = $p.stackdepth
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.next_line
    $p.write_literal("ntehnaeeneHssntehntesa")
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp n, which is now zero
    $p.write_comment("rshift")
    $p.next_line
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def -@ # unary minus
    $s[self.to_s] unless immediate?
    $p.write_literal("nentehs")
    $p.write_comment("unary-minus")
    $p.next_line
    EtaImmediate.instance
  end

  def +@ # unary plus
    $s[self.to_s] unless immediate?
    $p.write_comment("unary-plus")
    $p.next_line
    EtaImmediate.instance
  end

  def & (n) # bitwise and
    get_args(n)
    depth = $p.stackdepth
    $p.write_literal("ne") # result
    $p.write_num(2 ** 30) # counter
    $p.next_line     # at loop return stack: x n result counter <top>
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.write_literal("naeeneHss") # right shift the counter
    $p.write_literal("ntehnaeeneHssnteh") # right shift the result
    $p.write_literal("noeh") # stack : n result counter x
    $p.write_literal("naeenieh") # stack: result counter x/2 xcarry n
    $p.write_literal("naeenaeh") # stack: result counter x/2 n/2 ncarry xcarry
    $p.write_literal("nentehssnaesat") # add carries, subtract 2, txfer to next line if not 0
    $p.write_literal("noehne") # + 2 ** 30 to result
    $p.write_num(2 ** 30)
    $p.write_literal("ssnoehnoehnoeh")
    $p.next_line
    $p.write_literal("noehnoeha") # stack x n result counter
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp counter, which is now zero
    $p.write_literal("nteh")
    $p.write_chomp  # chomp n
    $p.write_literal("nteh")
    $p.write_chomp  # chomp x
    $p.write_comment("bitwise-and")
    $p.next_line  
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def | (n) # bitwise or
    get_args(n)
    depth = $p.stackdepth
    $p.write_literal("ne") # result
    $p.write_num(2 ** 30) # counter
    $p.next_line     # at loop return stack: x n result counter <top>
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.write_literal("naeeneHss") # right shift the counter
    $p.write_literal("ntehnaeeneHssnteh") # right shift the result
    $p.write_literal("noeh") # stack : n result counter x
    $p.write_literal("naeenieh") # stack: result counter x/2 xcarry n
    $p.write_literal("naeenaeh") # stack: result counter x/2 n/2 ncarry xcarry
    $p.write_literal("nentehss") # add carries, txfer to next line if 0
    $p.write_not
    $p.write_literal("at")
    $p.write_literal("noehne") # + 2 ** 30 to result
    $p.write_num(2 ** 30)
    $p.write_literal("ssnoehnoehnoeh")
    $p.next_line
    $p.write_literal("noehnoeha") # stack x n result counter
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp counter, which is now zero
    $p.write_literal("nteh")
    $p.write_chomp  # chomp n
    $p.write_literal("nteh")
    $p.write_chomp  # chomp x
    $p.write_comment("bitwise-or")
    $p.next_line  
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def ^ (n) # bitwise ex-or
    get_args(n)
    depth = $p.stackdepth
    $p.write_literal("ne") # result
    $p.write_num(2 ** 30) # counter
    $p.next_line     # at loop return stack: x n result counter <top>
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.write_literal("naeeneHss") # right shift the counter
    $p.write_literal("ntehnaeeneHssnteh") # right shift the result
    $p.write_literal("noeh") # stack : n result counter x
    $p.write_literal("naeenieh") # stack: result counter x/2 xcarry n
    $p.write_literal("naeenaeh") # stack: result counter x/2 n/2 ncarry xcarry
    $p.write_literal("nentehssntesat") # add carries, subtract 1, txfer to next line if not 0
    $p.write_literal("noehne") # + 2 ** 30 to result
    $p.write_num(2 ** 30)
    $p.write_literal("ssnoehnoehnoeh")
    $p.next_line
    $p.write_literal("noehnoeha") # stack x n result counter
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp counter, which is now zero
    $p.write_literal("nteh")
    $p.write_chomp  # chomp n
    $p.write_literal("nteh")
    $p.write_chomp  # chomp x
    $p.write_comment("bitwise-ex-or")
    $p.next_line  
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def ~ # complement (unary)
    $s[self.to_s] unless immediate?
    depth = $p.stackdepth
    $p.write_literal("ne") # result
    $p.write_num(2 ** 30) # counter
    $p.next_line     # at loop return stack: x result counter <top>
    loop_return = $p.linenumber
    $p.write_literal("neH")
    $p.write_not
    nn = $p.add_forward_xfer
    $p.write_literal("naeeneHss") # right shift the counter
    $p.write_literal("ntehnaeeneHssnteh") # right shift the result
    $p.write_literal("naeh") # stack : result counter x
    $p.write_literal("naee") # stack: result counter x/2 xcarry
    $p.write_literal("at")   # transfer to next line if not zero
    $p.write_literal("naehne") # + 2 ** 30 to result
    $p.write_num(2 ** 30)
    $p.write_literal("ssnaehnaeh")
    $p.next_line
    $p.write_literal("naehnaeha") # stack x result counter
    $p.write_num(loop_return)
    $p.write_literal("t")
    $p.next_line
    $p.complete_forward_xfer(nn)
    $p.write_chomp  # chomp counter, which is now zero
    $p.write_literal("nteh")
    $p.write_chomp  # chomp x
    $p.write_comment("unary-complement")
    $p.next_line
    $p.stackdepth = depth
    EtaImmediate.instance
  end

  def == (n)  # comparisons must return 0 on the stack for true
    get_args(n)
    $p.write_literal("s")
    $p.write_comment("equals")
    $p.next_line  
    EtaImmediate.instance
  end

# This is the compare algorithm
#
# compare x with y using divide, subtract and compare with zero 
# z = x - y 
# if (z==0) goto EQUAL 
# p = z - 1 
# if (p == 0) goto X>Y 
# if (z/p == 0) goto Y>X 
# else goto X>Y

  private
  def compare               # if x < y place zero, else place non-zero on the stack (y is at top of stack)
    $p.write_literal("sneHat")  # go to next line if they are not equal
    $p.write_chomp
    $p.write_literal("aaanenaesst")   # return non-zero false (equal is false)
    $p.next_line

    $p.write_literal("neHntesneHat")  
    $p.write_chomp         # p is 0, so x > y
    $p.write_chomp
    $p.write_literal("aaanentesst")  # return non-zero
    $p.next_line
    $p.write_literal("e")   # z / p - if this is zero then x < y
    $p.write_chomp          # chomp the modulus
    $p.next_line
  end

  def compare_or_eq                 # if x <= y place zero, else place non-zero on the stack
    $p.write_literal("sneHat")  # go to next line if they are not equal
    $p.write_chomp
    $p.write_literal("neaanenaesst")   # return zero true (equal is true)
    $p.next_line

    $p.write_literal("neHntesneHat")  
    $p.write_chomp         # p is 0, so x > y
    $p.write_chomp
    $p.write_literal("aaanentesst")  # return non-zero
    $p.next_line
    $p.write_literal("e")   # z / p - if this is zero then x < y
    $p.write_chomp          # chomp the modulus
    $p.next_line
  end
  public

  def < (n)
    get_args(n)
    depth = $p.stackdepth
    $p.write_comment("less-than")
    compare
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def > (n)
    get_args(n)
    depth = $p.stackdepth
    $p.write_literal("nteh")  # swap args and use < comparison
    $p.write_comment("greater-than")
    compare
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def <= (n)
    get_args(n)
    depth = $p.stackdepth
    $p.write_comment("less-than-or-equal")
    compare_or_eq
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def >= (n)
    get_args(n)
    depth = $p.stackdepth
    $p.write_literal("nteh")  # swap args and use < comparison
    $p.write_comment("greater-than-or-equal")
    compare_or_eq
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end

  def val= (a) # assignment - use someEtaInt.val as an lvalue... pity I can't overload '=' somehow
    if (a.integer?)
      $s[self.to_s] = a
      $p.write_comment("variable=#{a}")
    else
      $s.set(self.to_s)
      $p.write_comment("assign-variable-to-result")
    end
    $p.next_line
  end

  def val  # only used in certain methods for setting the return value
    $s[self.to_s]
    $p.next_line
    EtaImmediate.instance
  end

  def delete  # this gets rid of the EtaInt inside the eta program stack
    if immediate?
      $p.write_chomp
      $p.write_comment("delete-top-of-stack")
    else
      $s.delete(self.to_s)
      $p.write_comment("delete-variable")
    end
    $p.next_line
  end

  def dispose # this gets rid of the EtaInt inside ruby
    $s.dispose(self.to_s)
  end

  def print
    $s[self.to_s] unless immediate?
    $p.write_literal("o")
    $p.write_comment("output")
    $p.next_line
  end

  def print_int
    $s[self.to_s] unless immediate?
    if (@printint)
      $p.write_literal("a")    # save return address
      $p.write_literal("a")    # this code, like multiply, is written once and then called when required
      $p.write_num(@printint)
      $p.write_literal("t")
      $p.write_comment("print_int-called")
      $p.next_line
      $p.stackdepth = $p.stackdepth - 2
      return
    else
      $p.write_num($p.linenumber + 33)  # return address is immediately after this function
      @printint = $p.linenumber + 1
    end
    $p.next_line
    depth = $p.stackdepth
    $p.write_literal("nteh")    # bury return address
    $p.write_literal("neHne")
    compare    # less than zero?
    $p.write_literal("at")
    $p.write_num(45)  # minus sign
    $p.write_literal("onentehs")  # negate
    $p.next_line
    $p.write_literal("nenteh") # leading zero flag
    [9,8,7,6,5,4,3,2,1].each do |a|
      $p.write_num(10 ** a)
      $p.write_literal("enteh")
      $p.write_literal("neHnenoesHs") # subtract flag from res, jump if zero
      $p.write_not
      $p.write_literal("at")
      $p.write_literal("ne")
      $p.write_num(48)
      $p.write_literal("sso")
      $p.write_literal("ntehntesnteha") # subtract one from the flag, stick an extra item on the stack
      $p.next_line
      $p.write_chomp # chomp divide or the extra item
    end
    $p.write_literal("ne")
    $p.write_num(48)
    $p.write_literal("sso")
    $p.write_chomp # chomp flag
    $p.write_literal("anteht")  # go to return address
    $p.write_comment("output-number")
    $p.next_line
    $p.stackdepth = depth - 2
  end
end

####################################################################
# Class EtaImmediate
# Return an instance of this if you are returning a value on the 
# top of the stack
####################################################################

class EtaImmediate < EtaInt
  include Singleton

  def initialize
  end

  def immediate?
    true
  end

end

####################################################################
# Class Fixnum
# Methods to allow intermixing with EtaInts
# Because shifting and bitwise ops don't call coerce.
####################################################################

class Fixnum
  alias_method :_lshift, :<<
  def << (n)
    if (n.kind_of?(Numeric))
      _lshift n
    else
      $p.write_num(self)
      EtaImmediate.instance << n
    end
  end

  alias_method :_rshift, :>>
  def >> (n)
    if (n.kind_of?(Numeric))
      _rshift n
    else
      $p.write_num(self)
      EtaImmediate.instance >> n
    end
  end

  alias_method :_bwand, :&
  def & (n)
    if (n.kind_of?(Numeric))
      _bwand n
    else
      $p.write_num(self)
      EtaImmediate.instance & n
    end
  end

  alias_method :_bwor, :|
  def | (n)
    if (n.kind_of?(Numeric))
      _bwor n
    else
      $p.write_num(self)
      EtaImmediate.instance | n
    end
  end

  alias_method :_bwxor, :^
  def ^ (n)
    if (n.kind_of?(Numeric))
      _bwxor n
    else
      $p.write_num(self)
      EtaImmediate.instance ^ n
    end
  end
end

####################################################################
# Class EtaProgOutput
# Deals with the output stream, and keeps track of the stackdepth and
# line counter
####################################################################

class EtaProgOutput
  attr_accessor :stackdepth
  attr_reader :linenumber

  def initialize
    @p_out = ["",""] # program output array
    @p_comment = ["",""] # comment output array    
    @linenumber = 1
    @nextlinestacks = Array.new
    @nextlinestacknos = Array.new
    @stackdepth = 0
    @n = 0           # xfer points counter
  end

# transfer addresses are left in the prog as :n where n is the tag returned to the 
# condition code - these locations are filled when the condition code calls
# complete_forward_xfer having executed the block
  def add_forward_xfer(offset = 0)
    # adds :n to a line and moves to the next line
    # returns n
    @n = @n + 1
    @linenumber = @linenumber + offset
    write_literal "a" if offset != 0
    write_literal "n:#{@n}e"
    write_literal "t"
    @linenumber = @linenumber - offset
    @n
  end

  def complete_forward_xfer (n)
    # fills the current line into xfer n
    @p_out.each do |line|
      if (line =~ /:#{n}/) 
        line.sub!(/:#{n}/,etanum(@linenumber))
        break
      end
    end 
  end

  def write_chomp  # chomp a value from the stack
    write_literal("ne")
    write_literal("H")
    write_literal("s")
    write_literal("s")
  end

  def write_not
    write_literal(" ataaanentesst") # return non zero if they are equal
    next_line
    write_literal(" ne") # return zero for not equal.  Note spaces for stackdepth.
    next_line
  end

  def write_num (n)
    # write a number
    if (n < 0)
      write_literal("ne")
      write_literal ("n" + etanum(-n) + "e")
      write_literal("s")
    else
      write_literal ("n" + etanum(n) + "e")
    end
  end

  def write_literal (s) # write to the output... must use H to dup and h to roll so 
                        # we can keep a track of the stack
    @p_out[@linenumber] << s
    case s[0].chr
      when "n","a","i" then @stackdepth = @stackdepth + 1
      when "t" then @stackdepth = @stackdepth - 2
      when "o","s","h" then @stackdepth = @stackdepth - 1
    end
  end

  def write_comment (c)
    @p_comment[@linenumber] << c << " "
  end

  def etanum (n) # convert to an eta number string
    y = ""
    while (n > 0)
      y = ["h","t","a","o","i","n","s"][n%7] + y
      n = n / 7
    end
    y
  end

  def next_line
    @nextlinestacks.push(caller.join)  # record the stack at this time
    @nextlinestacknos.push(@linenumber)
    $p.write_comment(caller.join)

    @linenumber = @linenumber.next
    @p_out[@linenumber] = ""
    @p_comment[@linenumber] = ""
  end

  def fetchcondstart (stack)  # we can find where the loop needs to loop to from by looking at stack record
    s = stack.join
    @nextlinestacks.each_index do |a|
      if (@nextlinestacks[a] =~ /#{s}$/)
        return @nextlinestacknos[a]
      end
    end
  end

  def finish
    write_literal("anet")  # transfer to 0
    $p.write_comment("transfer-to-zero")
    if ($Debug)
      @p_out.each_index {|a| print @p_out[a].downcase.gsub(/\s+/,"") + "//aat// " + "##{a}#"+@p_comment[a] + "\n" if a>0}
    else
      @p_out.each_index {|a| print @p_out[a].downcase.gsub(/\s+/,"") + "\n" if a>0}
    end
  end
end

$p = EtaProgOutput.new

####################################################################
# Class EtaStack
# The stack has a work area at the top, and an array of variables below that.
# You can assign to a variable using array notation, and fetch it's value.
# All accesses to these variables go through this class.  Only EtaInt
# uses this class
####################################################################

class EtaStack
  attr_reader :stackarray

  def initialize
    @stackarray = Array.new
  end

  def rolldown(sp)  # roll a value down to its place in the stack in a more space efficient way
    $p.write_literal("ne")  # counter
    $p.next_line
    $p.write_literal("neH") # dup
    $p.write_num(sp)
    $p.write_literal("satneassanentesst")  # subtract, continue if != zero, eat count (with "neass"), exit (next line+1)
    $p.next_line
    $p.write_num(sp+1)
    $p.write_literal("hnteh") # rot stack down one more and swap back top 2 elems
    $p.write_literal("nentessaanaest") # inc count, start prev line again (a - 2)
    $p.next_line
    $p.stackdepth -= 3
  end

  def []= (name, value)  # assign to a stackslot
    if (slot = @stackarray.index(name))
      stackplace = $p.stackdepth - @stackarray.length + slot + 1
      $p.write_num(value) 
      $p.write_num(stackplace)
      $p.write_literal("h")
      $p.write_chomp       # eat the previous value
      stackplace = stackplace - 1
# this previous rolldown method is a bit faster, but takes too much code space
#      stackplace.times do
#        $p.write_num(stackplace)
#        $p.write_literal("h")
#      end
      rolldown(stackplace)
    else                       # add new slot
      @stackarray.push(name)
      stackplace = $p.stackdepth
      $p.write_num(value)
      rolldown(stackplace)
    end
    return @stackarray.index(name)  # return the slot for use by EtaArray
  end

  def [] (name)     # access a variable on the stack
    slot = @stackarray.index(name)
    stackplace = $p.stackdepth - @stackarray.length + slot
    $p.write_num(0)
    $p.write_num(stackplace)
    $p.write_literal("s")
    $p.write_literal("H")
  end

  def set (name) # set this variable to the top item of the stack
    slot = @stackarray.index(name)
    stackplace = $p.stackdepth - @stackarray.length + slot
    $p.write_num(stackplace)
    $p.write_literal("h")
    $p.write_chomp       # eat the previous value
    stackplace = stackplace - 1
    rolldown(stackplace)
  end

  def delete (name) # delete a stack variable
    slot = @stackarray.index(name)
    stackplace = $p.stackdepth - @stackarray.length + slot
    $p.write_num(stackplace)
    $p.write_literal("h")
    $p.write_chomp       # eat the value
  end

  def dispose (name) # dispose of the variable
    slot = @stackarray.index(name)
    @stackarray.delete_at(slot)
  end
end

$s = EtaStack.new

####################################################################
# Class InputBlock
# Input a block to the bottom of the stack, and allow access through
# []
####################################################################

class InputBlock
  @@blockexists = 0
  def initialize (n)
    if (@@blockexists == 1)
      raise "Can only have one input block"
    end
    depth = $p.stackdepth
    $p.write_num(n)
    $p.next_line
    $p.write_literal("i")
    (depth + 1).times do
      $p.write_num(depth + 1)
      $p.write_literal("h")
    end
    $p.write_literal("ntesneHantest")
    $p.write_chomp
    $p.write_comment("initialise-inputblock")
    $p.next_line
    @blocklen = n
    $p.stackdepth = depth
    @@blockexists = 1
  end

  def [] (n)
    get_1_arg(n)
    $p.write_num($p.stackdepth + @blocklen - 2)
    $p.write_literal("nte")
    $p.write_literal("h")
    $p.write_literal("s")
    $p.write_literal("ne")
    $p.write_literal("nte")
    $p.write_literal("h")
    $p.write_literal("s")
    $p.write_literal("H")
    $p.write_comment("fetch-value-from-input-block")
    $p.next_line
    EtaImmediate.instance
  end
end

####################################################################
# Class Table
# Read only array - select an item from a numeric array passed at 
# initialisation
####################################################################

class Table
  def initialize(t)  # t is a numeric (ruby) array
    @table = t
  end

  def [] (n)
    get_1_arg(n)
    if (@tline)
      $p.write_literal("a")    # save return address
      $p.write_literal("a")
      $p.write_num(@tline)
      $p.write_literal("t")
      $p.write_comment("table-called")
      $p.next_line
      $p.stackdepth = $p.stackdepth - 1
      return EtaImmediate.instance
    else
      $p.write_num($p.linenumber + @table.length + 3)  # return address is immediately after this function
      @tline = $p.linenumber + 1
      $p.next_line
    end

    depth = $p.stackdepth
    $p.write_literal("nteh")  # bury return address
    $p.write_literal("aanaehnentehsst")
    $p.next_line
    fx = Array.new
    @table.each do |e|
      $p.write_num(e)
      $p.write_literal("a")
      fx.push($p.add_forward_xfer)
      $p.next_line
    end
    fx.each do |f|
      $p.complete_forward_xfer(f)
    end
    $p.write_literal("ntehanteht")  # go to return address
    $p.write_comment("select-item-from-table")
    $p.next_line
    $p.stackdepth = depth - 1
    EtaImmediate.instance
  end
end

####################################################################
# Class EtaArray
# An array of EtaInts
# initialise with x=EtaArray.new(size)
# Access and set values with []
# With constant indices, use get and set for efficiency
####################################################################  

class EtaArray
  def initialize(n)
    @ea = Array.new(n)
    @size = n
    n.times do |c|
      @ea[c] = EtaInt.new
    end
    @slotstart = @ea[0].slot
  end

  def [](x)
    get_1_arg(x)
    stackplace = $p.stackdepth - $s.stackarray.length + @slotstart - 1
    $p.write_literal("ne")
    $p.write_num(stackplace)
    $p.write_literal("ne")
    $p.write_num(3)
    $p.write_literal("h")
    $p.write_literal("s")
    $p.write_literal("s")
    $p.write_literal("s")
    $p.write_literal("H")
    EtaImmediate.instance
  end

  def []=(x,v)
    get_1_arg(v)  # the index gets eval-ed first, so it must be an immediate value
    stackplace = $p.stackdepth - $s.stackarray.length + @slotstart
    $p.write_num(stackplace)
    $p.write_literal("ne")
    $p.write_num(3)
    $p.write_literal("h")
    $p.write_literal("s")
    $p.write_literal("s")   # stack is now value, followed by realstackplace at bottom
    $p.write_literal("neH") # dup real place
    $p.write_literal("h")   # halibut the oldval up
    $p.write_chomp          # eat the previous value
    $p.write_literal("neH") # dup stackplace
    $p.write_num(2)
    $p.write_literal("s")   # subtract 2 to make counter
    $p.next_line
    $p.write_num(1)
    $p.write_literal("h")   # swap stackplace to the top
    $p.write_literal("neH") # dup
    $p.write_literal("h")   # shift em down
    $p.write_num(2)
    $p.write_literal("h")   # move counter and stackplace back to top
    $p.write_num(2)
    $p.write_literal("h")
    $p.write_num(1)
    $p.write_literal("h")   # swap counter to the top
    $p.write_num(1)
    $p.write_literal("s")   # decrement it
    $p.write_literal("neH") # dup
    $p.write_literal("antes")
    $p.write_literal("t")   # go back to start of this line if not zero
    $p.write_chomp          # chomp counter, stackplace
    $p.write_chomp
    $p.next_line
  end

  def set(x,v)
    @ea[x].val = v
  end

  def get(x)
    @ea[x].val
  end

  def multiset()  # expecting num of vals to set at top, followed by the vals on the stack
                  # stackdepth is not valid, there are extra num items
    depth=$p.stackdepth
    $p.next_line
    $p.write_literal(" neHat neHss aanenoesst")   # dup, to next line if not zero else to end (a+3)
    $p.next_line
    $p.write_literal(" neH neH ne nteh ss ne")  # dup count, add count, add stackdepth
    stackplace = $p.stackdepth - $s.stackarray.length + @slotstart + 1
    $p.write_num(stackplace)
    $p.write_literal("ss naeh nteh") # stack now ...xx)(n)(x)(n+n+sd)
    $p.write_literal("neH") # dup real place
    $p.write_literal("h")   # halibut the oldval up
    $p.write_chomp          # eat the previous value
    $p.write_literal("neH") # dup stackplace
    $p.write_num(2)
    $p.write_literal("s")   # subtract 2 to make counter
    $p.next_line
    $p.write_num(1)
    $p.write_literal("h")   # swap stackplace to the top
    $p.write_literal("neH") # dup
    $p.write_literal("h")   # shift em down
    $p.write_num(2)
    $p.write_literal("h")   # move counter and stackplace back to top
    $p.write_num(2)
    $p.write_literal("h")
    $p.write_num(1)
    $p.write_literal("h")   # swap counter to the top
    $p.write_num(1)
    $p.write_literal("s")   # decrement it
    $p.write_literal("neH") # dup
    $p.write_literal("antes")
    $p.write_literal("t")   # go back to start of this line if not zero
    $p.write_chomp          # eat counter
    $p.write_chomp          # eat stackplace
    $p.write_literal("ntes")# dec n
    $p.write_literal("aanoest") # go to a-3
    $p.next_line
    $p.stackdepth=depth
  end
end


####################################################################
# Functions for general use
####################################################################  

def get_1_arg(n)  # fetches the arg - returns the cur line if arg is
                  # made here for loop return in ewhile
  if (true == n)
    $p.write_num(0)
    return $p.linenumber
  elsif (false == n)
    $p.write_not
    return nil
  elsif (n.kind_of?(Numeric))
    $p.write_num(n)
    return $p.linenumber
  elsif (!n.immediate?)
    n.val
    return $p.linenumber
  end
  nil
end

####################################################################
# Flow Control
# These functions take a block which is executed conditionally
# The stack needs to be in the same state before and after the
# block otherwise this system can't work.  You can't declare
# new variables in a conditional block, or do anything to change
# the stack depth
####################################################################  

def eif (cond)
  get_1_arg(cond)
  n = $p.add_forward_xfer
  $p.write_comment("start-of-if-block")
  $p.next_line
  depth = $p.stackdepth
  yield
  if ($p.stackdepth != depth)
    raise "Different stack depth after block, can't compile"
  end
  $p.write_comment("end-of-if-block")
  $p.next_line
  $p.complete_forward_xfer(n)
end

def eelse
  n = $p.add_forward_xfer(-1)
  $p.write_comment("start-of-else-block")
  depth = $p.stackdepth
  yield
  if ($p.stackdepth != depth)
    raise "Different stack depth after block, can't compile"
  end
  $p.write_comment("end-of-else-block")
  $p.next_line
  $p.complete_forward_xfer(n)
end

def ewhile (cond)
  loop_return = get_1_arg(cond)
  n = $p.add_forward_xfer
  $p.write_comment("start-of-while-block")
  loop_return = $p.fetchcondstart(caller) if !loop_return
  $p.next_line
  depth = $p.stackdepth
  yield
  if ($p.stackdepth != depth)
    raise "Different stack depth after block, can't compile"
  end
  $p.write_literal("a")
  $p.write_num(loop_return)
  $p.write_literal("t")
  $p.write_comment("end-of-while-block")
  $p.next_line
  $p.complete_forward_xfer(n)
end

####################################################################
# Thread Control
#
# Forkif works the same way as eif, but the block is
# executed by a new thread if the condition is true
#
# Threads should finish by calling eexit (if not returning a value)
# or by calling threadreturn with a value.
# This value can be picked up by its parent (or its parents ancestors
# if its parent has exited first) using the threadcollect instruction.
# Threadcollect takes a (numeric constant) parameter of how many threads 
# it is waiting for.
# This is the number of the values that will be placed in the $threadResults
# EtaArray.
# Threads that call eexit cannot be collected.
#
# Don't define new variables in a thread block.  The stackarray will
# get confused if you do.  This may be fixed later.
####################################################################  

$threadResults = EtaArray.new($MaxThreadCollect)

def forkif (cond)
  get_1_arg(cond)
  $p.write_not
  $p.write_literal("ne")  # fork to next line if condition
  $p.write_literal("a")
  $p.write_literal("s")
  $p.write_literal("t")
  $p.write_literal("a")   # and this thread jumps over block
  n = $p.add_forward_xfer
  $p.write_comment("start-of-forkif-block")
  $p.next_line
  depth = $p.stackdepth
  yield                  # it's the block's responsibility to exit cleanly
  $p.stackdepth = depth  # restore the stackdepth - thread had no effect
  $p.write_comment("end-of-forkif-block")
  $p.next_line
  $p.complete_forward_xfer(n)
end

def threadreturn (val)
  depth = $p.stackdepth
  get_1_arg(val)
  $p.write_literal("ne")
  $p.write_literal("e")
  $p.stackdepth = depth
end

def threadcollect (v)       # cannot exceed $MaxThreadCollect, but no runtime check
  get_1_arg(v)
  $p.write_literal(" nentehs")  # wait for n threads here
  $p.write_literal("o")
  $threadResults.multiset 
  $p.next_line
end

####################################################################
# Essential Functions
####################################################################

def eprint (*p) # print a list of things - strings, integers, EtaInts
  p.each do |s|
    if (s.kind_of?(EtaInt))
      s.print_int
    else
      if (s.kind_of?(Integer))
        $p.write_num(s)
        EtaImmediate.instance.print_int
      else
        s.each_byte do |a|
          $p.write_num(a)
          $p.write_literal("o")
        end
        $p.write_comment("eprint")
        $p.next_line
      end
    end
  end
end

def eexit
  $p.write_num(1)
  $p.write_num(0)
  $p.write_literal("t")
end

def input  # a single char
  $p.write_literal("i")
  $p.next_line
  EtaImmediate.instance
end

def input_number # in decimal, can be preceded by minus sign
  _ip = EtaInt.new(input)
  _num = EtaInt.new
  eif (_ip == ?-) {
    _ip.val = input
    ewhile (_ip != ?\n) {
      _num.val = ?0 - _ip + _num * 10
      _ip.val = input
    }
  }
  ewhile (_ip != ?\n) {
    _num.val = _num * 10 + _ip - ?0
    _ip.val = input
  }
  _num.val
  _num.delete
  _num.dispose
  _ip.delete
  _ip.dispose
  $p.write_comment("input-number")
  $p.next_line
  EtaImmediate.instance
end

def finish
  $p.finish
end

def write (s)  # try to keep track of stack
  numflag = 0
  nstr = ""
  s.gsub(/\n/, " ").each_byte do |b|
    if (numflag == 0)
      if (b != ?n)
        $p.write_literal(b.chr)
        if (b == ?t)
          $stderr.print("Warning: t instruction used in user supplied eta, possible stack corruption\n")
        end
      else
        nstr = "n"
        numflag = 1
      end
    else
      nstr << b.chr
      if (b == ?e)
        $p.write_literal(nstr)
        numflag = 0
      end
    end
  end
  if (numflag == 1)
    $p.write_literal(nstr)
    $stderr.print("Warning: unterminated number in user supplied eta, probable imminent structural integrity failure\n")
  end
end

def write_raw (s)
  $p.write_literal("[" + s.gsub(/\n/, " ") + "]")
end

def next_line
  $p.next_line
end

####################################################################
