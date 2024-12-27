#
#    This optimiser is part of the ETA C Compiler project by Stephen Sykes
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
def pass(a)
  b = []
  skip = false
  epush = /\$e\.push\(/
  eapush = /\$ea\.push\(/
  echomp = /\$e\.chomp/
  eachomp = /\$ea\.chomp/
  epop = /^\s*\$e\.pop/

  a.each_index {|i|
    if (a[i] =~ eapush && a[i+1] =~ eachomp) 
      a[i] = a[i+1] = nil
    end
    
    if (a[i] =~ epush && a[i+1] =~ echomp) 
        a[i] = a[i+1] = nil
    end
    if (a[i] =~ epush && a[i+1] =~ epop)
      if (!a[i].gsub!(/\$e.push\(([0-9]*)\)/, '$p.write_num(\1)'))
        a[i].gsub!(/\$e.push\((.*)\)/, '\1')
      end
      a[i+1] = nil
    end
    
    if (a[i] =~ epush && a[i+1] =~ /^\s*[^=]+=\s*\$e\.pop/)
      a[i] =~ /\$e.push\((.*)\)/
      v = $1
      a[i] = nil
      a[i+1].gsub!(/\$e\.pop/, "#{v}")
    end
    
    if (a[i] =~ epush && a[i+1] =~ eapush && a[i+2] =~ epop)
      if (!a[i].gsub!(/\$e.push\(([0-9]*)\)/, '$p.write_num(\1)'))
        a[i].gsub!(/\$e.push\((.*)\)/, '\1')
      end
      a[i+2] = a[i]
      a[i] = nil
    end
    
    if (a[i] =~ epush && a[i+1] =~ eapush && a[i+2] =~ /^\s*\$l\[.*\]\s*=\s*\$e\.topval/ && a[i+3] =~ echomp && a[i+4] =~ eachomp)
      a[i].gsub!(/\$e.push\((.*)\)/, '\1')
      a[i+2].gsub!(/\$e\.topval/, a[i])
      a[i] = a[i+1] = a[i+3] = a[i+4] = nil
    end
    
    if (a[i] =~ /\$e\.push\(EtaImmediate\.instance/ && a[i+1] =~ eapush && a[i+2] =~ /^#/ && a[i+3] =~ echomp && a[i+4] =~ eachomp)
      a[i] = "$p.write_chomp\n"
      a[i+1] = a[i+3] = a[i+4] = nil
    end

    if (a[i] =~ echomp && a[i+1] =~ eachomp && a[i+2] =~ epush && a[i+3] =~ eapush)
      a[i] = a[i+1] = nil
      a[i+2].gsub!(epush, "$e.topval=(")
      a[i+3].gsub!(eapush, "$ea.topval=(")
    end

    b << a[i]
  }
  b.compact
end

i = $<.readlines

i1 = pass(i)
i2 = pass(i1)
i2.each {|l| print l}

