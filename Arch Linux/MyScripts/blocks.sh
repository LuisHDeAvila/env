#!/bin/bash
ENTRY=$1

numberlines=$(wc -l $ENTRY | awk '{print $1}')
BLOCK=$(echo $(( numberlines/10 )))
sed -i 's/u003d//g' $ENTRY

for ((c=1;c<=10;c++)); do
	let inicio=$(( BLOCK*c ))
	cat $ENTRY | head -$inicio | tail -$BLOCK >> PARTE$c.txt
done
