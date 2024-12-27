#
#    These libraries are part of the ETA C Compiler project by Stephen Sykes
#
#    Copyright (C) 2003  Stephen Sykes
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#    Stephen Sykes - etacc.9.sts@xoxy.net
#

####################################################################
#
#  Dereference functions used by string library
#
####################################################################

$s_temp = EtaInt.new

def cstack_deref_to_temp
  eif($c.topval<0) {
    $s_temp.val = $globals[$c.topval + $globalsize]
  }
  eelse {
    $s_temp.val = $l[$c.topval]
  }
end

def estack_deref_to_temp
  eif($e.topval<0) {
    $s_temp.val = $globals[$e.topval + $globalsize]
  }
  eelse {
    $s_temp.val = $l[$e.topval]
  }
end

####################################################################
#
#  Printf
#
####################################################################

$printf_args = EtaArray.new(12)
$printf_inpercent = EtaInt.new
$printf_argpos = EtaInt.new

class Printf
  def Printf.do(arity)
    (arity-1).downto(0) {|i|
      $e.pop
      $printf_args.set(i, EtaImmediate.instance)
      $ea.chomp
    }

    $c.push($printf_args.get(0))

    $printf_inpercent.val = 0
    $printf_argpos.val = 1
    cstack_deref_to_temp
    ewhile($s_temp != 0) {
      eif($printf_inpercent == 1) {
        eif($s_temp == ?d) {
          eprint $printf_args[$printf_argpos]
          $printf_argpos.val = $printf_argpos + 1
        }
        eif($s_temp == ?c) {
          cprint $printf_args[$printf_argpos]
          $printf_argpos.val = $printf_argpos + 1
        }
        eif($s_temp == ?%) {
          eprint "%"
        }
        eif($s_temp == ?s) {
          $c.push($printf_args[$printf_argpos])
          cstack_deref_to_temp
          ewhile($s_temp != 0) {
            cprint $s_temp
            $c.inctopval
            cstack_deref_to_temp
          }
          $c.chomp
          $printf_argpos.val = $printf_argpos + 1
        }
        $printf_inpercent.val = 0
      }
      eelse {
        eif($s_temp == ?%) {
          $printf_inpercent.val = 1
        }
        eelse {
          cprint $s_temp
        }
      }
      $c.inctopval
      cstack_deref_to_temp
    }
    $c.chomp
    $e.push(0)  # return value
    $ea.push(0) # null
  end
end

####################################################################
#
# Getchar
#
####################################################################

class Getchar
  def Getchar.do(arity)
    $e.push(input)
    $ea.push(0) # null
  end
end

####################################################################
#
# Putchar
#
####################################################################

class Putchar
  def Putchar.do(arity)
    $e.topval
    write('o')
  end
end

####################################################################
#
# Astack - general purpose stack made from EtaArrays
#
####################################################################

class Astack
  def initialize(size, fsize)
    @size = size
    @fsize = fsize
    @s = EtaArray.new(size)
    @top = EtaInt.new(-1)
    if (fsize > 0)
      @frames = EtaArray.new(fsize)
      @ftop = EtaInt.new(-1)
    end
    @temp = EtaInt.new
  end

  def push(x)
    get_1_arg(x)
    @top.val = @top + 1
    eif (@top == @size) {
      eprint("!!\n")
      eexit
    }
    @s[@top] = EtaImmediate.instance
  end

  def push_next_line
    @top.val = @top + 1
    eif (@top == @size) {
      eprint("!!\n")
      eexit
    }
    @s[@top] = $p.linenumber + 7
  end

  def [](n)
    @s[n]
  end

  def []=(n,v)
    @s[n] = v
  end

  def local2abs(n)
    @frames[@ftop] + n + 1
  end

  def topval
    @s[@top]
  end

  def topval=(n)
    @s[@top] = n
  end

  def inctopval
    @s[@top] = @s[@top] + 1
  end

  def dectopval
    @s[@top] = @s[@top] - 1
  end

  def pop
    @s[@top]
    @top.val = @top - 1
    EtaImmediate.instance
  end

  def chomp
    @top.val = @top - 1
  end

  def newframe(n)
    @ftop.val = @ftop + 1
    eif (@ftop == @fsize) {
      eprint("Frame stack overflow\n")
      eexit
    }
    @frames[@ftop] = @top
    @top.val = @top + n
  end

  def popframe
    @top.val = @frames[@ftop]
    @ftop.val = @ftop - 1
  end
end

####################################################################
#
# deref_assignment - code to assign value to a location (*x = y)
# address should be on top of the stack, value below
#
####################################################################

def deref_assignment(ass_op)
  $e.chomp # useless value, we are interested in the address only
  eif ($ea.topval<0) {
    if (ass_op == "=")
      $globals[$ea.pop + $globalsize] = $e.topval
    else
      eval("$globals[$ea.topval + $globalsize] = $globals[$ea.topval + $globalsize] #{ass_op[0..-2]} $e.topval")
      $ea.chomp
    end
  }
  eelse {
    if (ass_op == "=")
      $l[$ea.pop] = $e.topval
    else
      eval("$l[$ea.topval] = $l[$ea.topval] #{ass_op[0..-2]} $e.topval")
      $ea.chomp
    end
  }
end

####################################################################
#
# dereference
#
####################################################################

def dereference
  $ea.topval=$e.topval
  eif($ea.topval<0) {
    $e.topval = $globals[$ea.topval + $globalsize]
  }
  eelse {
    $e.topval = $l[$ea.topval]
  }
end

####################################################################
#
# postinc
#
####################################################################

def postinc
  eif($ea.topval<0) {
    $globals[$ea.topval + $globalsize] = $globals[$ea.topval + $globalsize] + 1
  }
  eelse {
    $l[$ea.topval] = $l[$ea.topval] + 1
  }
end

####################################################################
#
# postdec
#
####################################################################

def postdec
  eif($ea.topval<0) {
    $globals[$ea.topval + $globalsize] = $globals[$ea.topval + $globalsize] - 1
  }
  eelse {
    $l[$ea.topval] = $l[$ea.topval] - 1
  }
end

####################################################################
#
# preinc
#
####################################################################

def preinc
  postinc
  $e.inctopval
end

####################################################################
#
# predec
#
####################################################################

def predec
  postdec
  $e.dectopval
end
