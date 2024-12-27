require 'eta-rb'

def sornot(beer)
  eif (beer != 1) {
    eprint "s"
  }
end

beer = EtaInt.new(99)
ewhile (beer > 0) {
  eprint beer, " bottle"
  sornot(beer)
  eprint " of beer on the wall, ", beer, " bottle"
  sornot(beer)
  eprint " of beer\nTake one down, pass it around\n"
  beer.val = beer - 1
  eprint beer, " bottle"
  sornot(beer)
  eprint " of beer on the wall\n\n"
}
eprint "Mmmm, beer."

finish
