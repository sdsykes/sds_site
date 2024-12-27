require 'theta-rb'

def tryit(n,x)
  forkif (true) {
    forkif(true) {
      eif (n % x == 0) {
        threadreturn(x)
      }
      eelse {
        threadreturn(0)
      }
    }
    threadcollect(1)
    threadreturn($threadResults[0])
  }
end

eprint "Enter number to be factorised: "
n = EtaInt.new(input_number)

eprint "Forking threads...\n"
tryit(n,2)
tryit(n,3)
tryit(n,5)
tryit(n,7)
tryit(n,11)
tryit(n,13)
tryit(n,17)
tryit(n,19)

eprint "Collecting threads...\n"
threadcollect(8)
8.times {|z|
  eif ($threadResults[z] != 0) {
    eprint $threadResults[z], "\n"
  }
}
eexit
finish
