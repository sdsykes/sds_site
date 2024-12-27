require 'eta-rb'
eprint "ETA Factorial Generator\n"
eprint "Enter number (12 is max): "
num = EtaInt.new(input_number)
result = EtaInt.new(num)

eif (num > 12) {
  eprint "Number too large"
}
eelse {
  eif (num < 0) {
    eprint "Negative numbers are not allowed"
  }
  eelse {
    eif (num == 0) {
      eprint "Zero factorial is not defined"
    }
    eelse {
      ewhile (num != 1) {
        num.val = num - 1
        result.val = num * result
      }
      eprint "Factorial is ", result
    }
  }
}
finish
