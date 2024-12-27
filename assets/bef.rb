####################################################################
# Ruby Befunge to ETA compiler
#
# S.D.Sykes Feb 2002
#
# Usage ruby bef.rb <inputfile.bef >outputfile.eta
#
####################################################################

require 'eta-rb.rb'

MaxStack = 100

ipr = EtaInt.new
ipc = EtaInt.new
ipcomposite = EtaInt.new
dir = EtaInt.new  # right = 0, left = 1, up = 2, down = 3
curinst = EtaInt.new
$stackptr = EtaInt.new
$popa = EtaInt.new
$popb = EtaInt.new
pushval = EtaInt.new
stringmode = EtaInt.new
rnd = EtaInt.new(1)  # random seed

prog= $<.readlines

$stderr.print "\nmaking stack array\n"
eprint "Making stack\n"
$stack = EtaArray.new(MaxStack)

$stderr.print "making field array length #{prog.length}\n"
eprint "Making field\n"
field = EtaArray.new(prog.length*80)
# field = EtaArray.new(25*80)  # strictly, the additional rows should be available for g & p

prog.each_index do |a|
  $stderr.print "setting field row #{a}\n"
  c = 0
  prog[a].each_byte do |ch|
    if (ch != ?\n) 
      field.set(a*80+c,ch)
      c += 1
      $stderr.print ch.chr
    end
  end
  c.upto(79) do |d|
    field.set(a*80+d,(? ))
  end
  $stderr.print "\n"
end

def pop1
  eif ($stackptr == 0) {
    $popa.val = 0
  }
  eelse {
    $stackptr.val = $stackptr - 1
    $popa.val = $stack[$stackptr]
  }
end

def pop2
  eif ($stackptr == 0) {
    $popa.val = 0
    $popb.val = 0
  }
  eif ($stackptr == 1) {
    $popa.val = $stack[0]
    $popb.val = 0
    $stackptr.val = 0
  }
  eif ($stackptr > 1) {
    $stackptr.val = $stackptr - 1
    $popa.val = $stack[$stackptr]
    $stackptr.val = $stackptr - 1
    $popb.val = $stack[$stackptr]
  }
end

def push (pval)
  $stack[$stackptr.val] = pval
  $stackptr.val = $stackptr + 1
  eif ($stackptr == MaxStack) {
    eprint "/nStack overflow/n"
    eexit
  }
end

$stderr.print "begin compiling instruction loop\n"
ewhile (true) {
 ipcomposite.val = ipr * 80 + ipc
 curinst.val = field[ipcomposite]
 eif (stringmode == 0) {
  $stderr.print "arithmetic functions\n"
  eif (curinst == ?+) {
    pop2
    pushval.val = $popb + $popa
    push pushval
  }
  eif (curinst == ?-) {
    pop2
    pushval.val = $popb - $popa
    push pushval
  }
  eif (curinst == ?*) {
    pop2
    pushval.val = $popb * $popa
    push pushval
  }
  eif (curinst == ?/) {
    pop2
    pushval.val = $popb / $popa
    push pushval
  }
  eif (curinst == ?%) {
    pop2
    pushval.val = $popb % $popa
    push pushval
  }
  $stderr.print "logic functions\n"
  eif (curinst == ?!) {  # not
    pop1
    eif ($popa == 0) {
      pushval.val = 1
      push pushval
    }
    eelse {
      pushval.val = 0
      push pushval
    }
  }
  eif (curinst == ?`) {  # greater than
    pop2
    eif ($popb > $popa) {
      pushval.val = 1
      push pushval
    }
    eelse {
      pushval.val = 0
      push pushval
    }
  }
  $stderr.print "stack operations\n"
  eif (curinst == ?$) {  # pop
    pop1
  }
  eif (curinst == ?:) {  # dup
    pop1
    push $popa
    push $popa
  }
  eif (curinst == ?\\) { # swap
    pop2
    push $popa
    push $popb
  }
  $stderr.print "numbers\n"
  eif (curinst == ?0) {
    pushval.val = 0
    push pushval
  }
  eif (curinst == ?1) {
    pushval.val = 1
    push pushval
  }
  eif (curinst == ?2) {
    pushval.val = 2
    push pushval
  }
  eif (curinst == ?3) {
    pushval.val = 3
    push pushval
  }
  eif (curinst == ?4) {
    pushval.val = 4
    push pushval
  }
  eif (curinst == ?5) {
    pushval.val = 5
    push pushval
  }
  eif (curinst == ?6) {
    pushval.val = 6
    push pushval
  }
  eif (curinst == ?7) {
    pushval.val = 7
    push pushval
  }
  eif (curinst == ?8) {
    pushval.val = 8
    push pushval
  }
  eif (curinst == ?9) {
    pushval.val = 9
    push pushval
  }
  $stderr.print "input functions\n"
  eif (curinst == ?&) {  # input decimal value
    pushval.val = input_number
    push pushval
  }
  eif (curinst == ?~) {  # input character
    pushval.val = input
    push pushval
  }
  eif (curinst == ?") {  # stringmode
    stringmode.val = 1
  }
  $stderr.print "output functions\n"
  eif (curinst == ?.) {  # print decimal value
    pop1
    $popa.print_int
    eprint " "
  }
  eif (curinst == ?,) {  # print character
    pop1
    $popa.print
  }
  $stderr.print "get and put\n"
  eif (curinst == ?g) {
    pop2
    pushval.val = field[$popa * 80 + $popb]
#    eif (pushval > 127) {  # the field only holds (signed according to mtfi) chars
#      pushval.val = pushval - 256
#    }
#    eif (pushval < -128) {
#      pushval.val = pushval + 256
#    }
    push pushval
  }
  eif (curinst == ?p) {
    pop2
    pushval.val = $popa * 80 + $popb
    pop1
    $popa.val = $popa % 256  # need to fix if already negative?
    eif ($popa > 127) {  # the field only holds (signed according to mtfi) chars
      $popa.val = $popa - 256
    }
    eif ($popa < -128) {
      $popa.val = $popa + 256
    }
    field[pushval.val] = $popa
  }
  $stderr.print "flow control functions\n"
  eif (curinst == ?>) {  # right
    dir.val = 0
  }
  eif (curinst == ?<) {  # left
    dir.val = 1
  }
  eif (curinst == ?^) {  # up
    dir.val = 2
  }
  eif (curinst == ?v) {  # down
    dir.val = 3
  }
  eif (curinst == ??) {  # random
    rnd.val = 16807 * (rnd % 127773) - 2836 * (rnd / 127773)
    dir.val = rnd % 4
  }
  eif (curinst == ?#) {  # bridge
    eif (dir == 0) {  # right
      ipc.val = ipc + 1
      eif (ipc == 80) {
        ipc.val = 0
      }
    }
    eif (dir == 1) {  # left
      ipc.val = ipc - 1
      eif (ipc == -1) {
        ipc.val = 79
      }
    }
    eif (dir == 2) {  # up
      ipr.val = ipr - 1
      eif (ipr == -1) {
        ipr.val = prog.size - 1
      }
    }
    eif (dir == 3) {  # down
      ipr.val = ipr + 1
      eif (ipr == prog.size) {
        ipr.val = 0
      }
    }
  }
  $stderr.print "conditionals\n"
  eif (curinst == ?_) {
    pop1
    eif ($popa == 0) {
      dir.val = 0
    }
    eelse {
      dir.val = 1
    }
  }
  eif (curinst == ?|) {
    pop1
    eif ($popa == 0) {
      dir.val = 3
    }
    eelse {
      dir.val = 2
    }
  }
  $stderr.print "termination\n" 
  eif (curinst == ?@) {  # exit
    eexit
  }
 }
 $stderr.print "stringmode\n"
 eelse {  # stringmode
   push curinst
   eif (curinst == ?") {
     stringmode.val = 0
     pop1
   }
 }
 $stderr.print "ip movement\n"
 eif (dir == 0) {  # right
  ipc.val = ipc + 1
  eif (ipc == 80) {
     ipc.val = 0
  }
 }
 eif (dir == 1) {  # left
  ipc.val = ipc - 1
  eif (ipc == -1) {
     ipc.val = 79
  }
 }
 eif (dir == 2) {  # up
  ipr.val = ipr - 1
  eif (ipr == -1) {
     ipr.val = prog.size - 1
  }
 }
 eif (dir == 3) {  # down
  ipr.val = ipr + 1
  eif (ipr == prog.size) {
     ipr.val = 0
  }
 }
}
$stderr.print "finished compilation\n"
finish
