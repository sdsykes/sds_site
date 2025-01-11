class Bf
  def initialize
    @a = [0] * 30000
    @b = []
    @p = 0
    @x = 0
  end

  def r
    @p += 1
  end

  def l
    @p -= 1
  end

  def i
    @a[@p] = (@a[@p] + 1) % 256
  end

  def d
    @a[@p] = (@a[@p] - 1) % 256
  end

  def o
    if @a[@p] == -1
      print 255.chr
    else
      print @a[@p].chr
    end
  end

  def n
    @a[@p] = $stdin.getc || -1
  end

  def j
    @x += 1
    if !$j
      if @a[@p] == 0
        $j = @x
      else
        @b[@x] = $i
      end
    end
  end

  def e
    if $j || @a[@p] == 0
      $j = false if $j == @x
      @x -= 1
    else
      $i = @b[@x]
    end
  end

  def b
    10.times {|a| print @a[a].chr}
  end
end

b = Bf.new
$i = 0
p = $<.readlines.join.tr('^><+\-.,[]#','').tr('><+\-.,[]#', 'rlidonjeb')
while $i < p.size
  c = p[$i].chr
  if !$j || c == "j" || c == "e"
    b.send(c)
  end
  $i += 1
end
