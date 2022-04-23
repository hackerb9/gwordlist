#!/bin/bash

# Given a word, show a "popularity" score based on number of
# occurrences and number of books it appeared in.

# Uses ug for fast grep of compressed files.

if [[ -z "$1" ]]; then
    echo "Usage: $0 <word> [word ...]"
    exit 1
fi

for word; do
    echo -n "$word:	"
    ug -z "^$word	"  1-000??-of-00024.gz |
	tr '\t' '\n' |
	awk -F, '$2>0 {popularity += log($2) * $3; }
    	    	 END { printf("%'\''f\n", popularity); }'
done


