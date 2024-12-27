require 'eta-rb'

$bd = [EtaInt.new(-1), EtaInt.new(-2), EtaInt.new(-3), EtaInt.new(-4), EtaInt.new(-5), EtaInt.new(-6), EtaInt.new(-7), EtaInt.new(-8), EtaInt.new(-9)]

lines = [{0=>[1,2],1=>[0,2],2=>[0,1],3=>[4,5],4=>[3,5],5=>[3,4],6=>[7,8],7=>[6,8],8=>[6,7]},
         {0=>[3,6],1=>[4,7],2=>[5,8],3=>[0,6],4=>[1,7],5=>[2,8],6=>[0,3],7=>[1,4],8=>[2,5]},
         {0=>[4,8],2=>[4,6],4=>[0,8],6=>[2,4],8=>[0,4]},
         {4=>[2,6]}]

m = EtaInt.new
myplay = EtaInt.new
$finflag = EtaInt.new

def printbd
  9.times do |c|
    eif ($bd[c] < 0) {
      eprint " "
    }
    eif ($bd[c] == 1) {
      eprint "X"
    }
    eif ($bd[c] == 2) {
      eprint "O"
    }
    if (c == 2 || c == 5 || c == 8)
      eprint "\n"
      if (c != 8)
        eprint "-----\n"
      end
    else
      eprint "|"
    end
  end
  eprint "\n"
end

def windetect
  3.times do |c| # horizontal
    eif ($bd[c * 3] == $bd[c * 3 + 1]) {
      eif ($bd[c * 3 + 1] == $bd[c * 3 + 2]) {
        eif ($bd[c * 3] == 1) {
          eprint "Game over: you win"
        }
        eelse {
          eprint "Game over: I win"
        }
        eexit
      }
    }
  end
  3.times do |c| # vertical
    eif ($bd[c] == $bd[c + 3]) {
      eif ($bd[c + 3] == $bd[c + 6]) {
        eif ($bd[c] == 1) {
          eprint "Game over: you win"
        }
        eelse {
          eprint "Game over: I win"
        }
        eexit
      }
    }
  end
  2.times do |c| # diagonal
    eif ($bd[c * 2] == $bd[4]) {
      eif ($bd[8 - c * 2] == $bd[4]) {
        eif ($bd[4] == 1) {
          eprint "Game over: you win"
        }
        eelse {
          eprint "Game over: I win"
        }
        eexit
      }
    }
  end
  $finflag.val = 1
  9.times do |c| # finished?
    eif ($bd[c] < 0) {
      $finflag.val = 0
    }
  end
  eif ($finflag == 1) {
    eprint "Game over: draw"
    eexit
  }
end

eprint "Welcome to ETA noughts and crosses\n"
eprint "1|2|3\n-----\n4|5|6\n-----\n7|8|9\n\n"
ewhile (true) {
  eprint "Move [1-9]: "
  m.val = input_number - 1
  9.times do |c|
    eif (m == c) {
      eif ($bd[c] < 0) {
        $bd[c].val = 1
        m.val = -2
      }
    }
  end
  eif (m == -1) {
    eprint "Turn skipped"
  }
  eif (m > 0) {
    eprint "Illegal move, turn forfeited\n"
  }
  printbd
  windetect

  myplay.val = -1
  9.times do |c|
    eif ($bd[c] < 0) {
      4.times do |d|
        if (lines[d].include? c)
          eif ($bd[lines[d][c][0]] == 2) {
            eif ($bd[lines[d][c][1]] == 2) {
              myplay.val = c
            }
          }
        end
      end
    }
  end
  eif (myplay == -1) {
   9.times do |c|
    eif ($bd[c] < 0) {
      4.times do |d|
        if (lines[d].include? c)
          eif ($bd[lines[d][c][0]] == 1) {
            eif ($bd[lines[d][c][1]] == 1) {
              myplay.val = c
            }
          }
        end
      end
    }
   end
  }
  eif (myplay == -1) {  # choose any move now
    [4,2,6,8,0,7,5,3,1].each do |c|
      eif (myplay == -1) {
        eif ($bd[c].val < 0) {
          myplay.val = c
        }
      }
    end
  }
  eprint "My move: ", myplay + 1, "\n"
  9.times do |c|
    eif (myplay == c) {
      $bd[c].val = 2
    }
  end
  printbd
  windetect
}

finish