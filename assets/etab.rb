# eta beautifier
#
words = IO.readlines("usrdictwords")
#words = IO.readlines("dirtywords")

$profiles = Hash.new

words.each do |w|
  w.chomp!
  w.gsub!(/\r/,"")
  # exclude some words I don't want to see in the output here
  if (w =~ /[a-z]/ && w !~ /(cf)|(Pl)|(Ft)|(Rd)|(du)|(Wu)|(Mt)|(Cluj)|(ppm)|(Mbabane)|(St)|(Nguyen)/)
    index = w.downcase.gsub(/[bcdfgjklmpqruvwxyz]/,"")
    if (w.length > 1 || index.length > 0)
      if ($profiles[index])
        $profiles[index] = $profiles[index] + "|" + w
      else
        $profiles[index] = w
      end
    end
  end
end

def getword(p)
  if ($profiles[p])
    ar = $profiles[p].split("|")
    ar[rand(ar.length)]
  else
    nil
  end
end

outstr = String.new("")
ucflag = 0
while gets
  i = 0
  $_.chomp!
  while (i < $_.length)
    testar = [2,6,5,4,3,1,0]
    testar = [2,5,4,3,6,1,0] if rand(3)==1
    testar = [1,3,2,6,5,4,0] if rand(3)==1
    testar.each do |a|
      if (getword($_[i..i+a]) || a==0)
        if (ucflag == 0)
          outstr << (getword($_[i..i+a])?getword($_[i..i+a]):$_[i]) << " "
        else
          if (getword($_[i..i+a]))
            outstr << getword($_[i..i+a]).capitalize << " "
          else
            outstr << $_[i].chr.capitalize << " "
          end
          ucflag = 0
        end
        outstr.capitalize! if i == 0
        i = i + a + 1
        break
      end
    end
    if (rand(5)==1)
      outstr << getword("") << " "
    end
    if (outstr !~ /[,.:] *$/)
      if (rand(5)==1)
        outstr.gsub!(/ +$/, ", ")
      elsif (rand(9)==1)
        outstr.gsub!(/ +$/, ". ")
        ucflag = 1
      elsif (rand(35)==1)
        outstr.gsub!(/ +$/, ": ")
      end
    end
  end
  if (outstr == "")
    outstr = getword("").capitalize
    outstr = outstr << " " << getword("") if rand(2)==1
  end
  outstr = outstr.gsub(/^\s*/,"").gsub(/\s*$/,"")   # top and tail spaces
  outstr = outstr.gsub(/\ss\s/,"s ").gsub(/\ss$/,"s") # move single 's's to end of prev word
  outstr = outstr.gsub(/\s\s+/," ") # remove multiple spaces
  outstr = outstr.gsub(/[,.:]$/, "") # remove trailing punctuation
  print outstr, ".\n"
  outstr = ""
end
