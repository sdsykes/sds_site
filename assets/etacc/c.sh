#
#    This compiler script is part of the ETA C Compiler project by Stephen Sykes
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
ETAPATH=~sds/ETA/etacc
for i in $@
do
  cpp -I$ETAPATH $i | grep -v '^#' >/tmp/$$
  if $ETAPATH/parser 30 /tmp/$$ >$i.rr; then
    if ruby $ETAPATH/optimise.rb <$i.rr >$i.rro; then
      ruby -I$ETAPATH $i.rro >$i.eta
    fi
  fi
  rm /tmp/$$
  if ! test -s $i.eta; then
      rm $i.eta
  fi
done
