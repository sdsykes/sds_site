require 'theta-rb.rb'

x = EtaInt.new(0)
i = EtaInt.new
z = EtaInt.new

forkif(true) {
  threadreturn(input)
}

ewhile(true) {
  forkif($threadResults[0] == 0) {
    eprint x
    threadreturn(0)
  }
  forkif($threadResults[0] != 0) {
    threadreturn(input)
  }
  i.val = 10
  ewhile (i > 0) {
    i.val = i - 1
  }
  threadcollect(1)
  eif ($threadResults[0] > 0) {
    eif ($threadResults[0] > ?d) {
      x.val = x + 1
    }
    eelse {
      x.val = x - 1
    }
    z.val = input # chomp newline
  }
}

finish
