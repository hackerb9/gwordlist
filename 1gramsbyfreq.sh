#!/bin/bash -e

# 1gramsbyfreq.sh: create lists of the most frequently used English words. 

# These wordlists are derived from Google's n-Grams corpus which is
# freely usable under a Creative Commons "CC-BY 3.0" license. (See
# books.google.com/ngrams)

# Technique: Read every word from the Google corpus into an
# associative array and accumulate a count per word. Words of
# different types are mushed together. ("watch_VERB" and "watch_NOUN"
# become just "watch").

# Words with different capitalizations are mushed together ("the",
# "The", "THE"), but the most common usage is retained. ("London", not
# "london").

# Side note 1: The raw data is >14GB, and I had assumed awk would take
# a lot of memory for such an array made from that much data, but no,
# there were a lot of repeated entries for the same word in different
# years.

# Side note 2: I presume someone must have done this before, but if so
# they sure didn't make it easy to find. Googling just keeps leading
# me to wordfreq.info with some guy trying to sell his datasets under
# a restrictive license.

tempfile="/dev/shm/temp.txt"
if ! touch "$tempfile"; then tempfile="temp.txt"; fi


# Download 14 GiB of data (and awk it down to one ten-thousandth the size.)
echo "PHASE 0: Download all Google nGrams (> 5 GiB)" >&2

# Google Books v3.0 (20200217) comes as 24 files (0 to 23)
wget --no-clobber http://storage.googleapis.com/books/ngrams/books/20200217/eng/1-000{00..23}-of-00024.gz

echo "PHASE 1: Accumulating count of usage for every word in Google nGrams" >&2
for file in 1-*-of-*.gz; do
    if [[ -s "$file-accumcache" && "$file-accumcache" -nt "$file" ]]; then
	echo "$file-accumcache: using cached file" >&2
    else
	regenallwords=1
	zcat "$file" |
	    awk -v filename="$file" -v tick="'" > "$tempfile" '
BEGIN { 
	"tput el1" | getline cb;
	if (length(cb)==0) 
	  cb="\r                                                  \r";
}
{
  # Get rid of optional trailing part of speech: "as_well_VERB" -> "as_well"
  word=gensub("_[A-Z]+","", "" , $1);
  array[word]+=$3;
}
NR%10^5==0 {
    printf("%s\r%s, ", cb, filename) >"/dev/stderr"; 
    printf("line: %gM\t", NR/1E6) >"/dev/stderr"; 
    printf("%s %"tick"d", word, array[word]) >"/dev/stderr";
}
END { 
      print "."  >"/dev/stderr"; 
      for (word in array)  print word "\t" array[word]; 
}
'
	mv $tempfile "$file-accumcache"
    fi
done

if [[ "$regenallwords" || ! -s "allwords.txt" ]]; then
    echo "Concatenating all 1gram caches to allwords.txt" >&2 
    cat 1-*-of-*.gz-accumcache > "allwords.txt"
fi

# Sort most common words to the top
if [ -s "casesensitivefreq.txt" -a "casesensitivefreq.txt" -nt "allwords.txt" ]; then
    echo "Skipping preliminary sort, casesensitivefreq.txt is newer than allwords.txt">&2
else
    echo "Preliminary sort of allwords.txt, saving to casesensitivefreq.txt" >&2
    sort -rn -k2 "allwords.txt" > "casesensitivefreq.txt"
fi

# Mush together case-insensitively, retaining the most common capitalization.

echo "PHASE 2: Merging case-insensitively (The, THE, the)" >&2
if [[  "1gramsbyfreq.txt" -nt "casesensitivefreq.txt" ]]; then
    echo "Skipping merge: 1gramsbyfreq.txt is newer than casesensitivefreq.txt." >&2
else
    cat "casesensitivefreq.txt" | awk -v tick="'" '
    BEGIN { 
	    "tput el1" | getline cb;
	    if (length(cb)==0) 
	      cb="\r                                                  \r";
    }
    { 
      word=tolower($1);
      if (array[word]==0 && word != $1) {
	capitalization[word]=$1;
	if (NR%10000==0)
	  printf("%s\rKeeping capitalization of (%"tick"d) %s", cb, NR, capitalization[word]) >"/dev/stderr";
      }
      array[word]+=$2;
    }
    END { 
	 printf ("%s\rSaving...", cb)  >"/dev/stderr";
	 for (word in array)  {
	   if (capitalization[word]) 
	      print capitalization[word] "\t" array[word]; 
	   else
	      print word "\t" array[word]; 
	 }
	 print "."  >"/dev/stderr";
    }
    ' > "$tempfile"

    echo "Re-sorting results to 1gramsbyfreq.txt" >&2
    sort -rn -k2 "$tempfile" > "1gramsbyfreq.txt"
fi

# Now make a pretty version, showing percentage and accumulation.
echo "PHASE 3: Creating prettified version, frequency-all.txt" >&2

if [[ "frequency-all.txt" -nt "1gramsbyfreq.txt" ]]; then
    echo "Skipping prettification. frequency-all.txt is newer than 1gramsbyfreq.txt" >&2
else
    echo -n "Finding total words... " >&2
    totalwords=$(awk '{sum+=$2} END{print sum}' < 1gramsbyfreq.txt)
    printf "%'d\n" "$totalwords" >&2

    echo -n "Accumulating percentages for each word, saving in frequency-all.txt" >&2
    cat 1gramsbyfreq.txt | awk -v tick="'" -v totalwords=$totalwords '
    BEGIN {
      printf( "#%-9s %-20s\t%14s\t%12s\t%12s\n", 
	      "RANKING", "WORD", "COUNT", "PERCENT", "CUMULATIVE" );
    }
    {
      percent=100*$2/totalwords; 
      cum+=percent; 
      printf( "%-10s %-20s\t%"tick"14d\t%12f%%\t%12f%%\n", NR, $1, $2, percent, cum );
    }
    END { print "."  >"/dev/stderr"; }
    ' > frequency-all.txt
fi


# It's useful to pare the set down to the most useful words
# * consist of only ASCII alphabetic letters, no number, symbols, or Unicode
# * must appear in a dictionary, such as WordNet or Websters1913 (gcide)
# * must have at least one vowel
# * no curse words or other stop words ("et" "al" "y" "de" "le" "des" "un" "von" "di")

# * maybe cut off if it occurs less than 100,000 times in the corpus.
#   Or maybe not... this would rule out publishable, ventriloquism,
#   behead, ungentlemanly, fisticuffs, and headscarf.
#   "Mewl" only occurs 6,000 times in the entire trillion word corpus.

echo "PHASE 4: Now extracting valid words by comparing to dictionaries." >&2
set -- subphase {a..z}
for dict in wn gcide oed; do
    shift 
    output=alpha1gramsbyfreq-$dict.txt
    echo "PHASE 4$1: using dictionary '$dict' to create $output" >&2
    if ! dict -h localhost -D | grep -q $dict; then
	echo "    '$dict' database is not installed locally. Skipping."
	continue
    fi

    if [[ -s "$output" && "$output" -nt "1gramsbyfreq.txt" ]]; then
	echo "    Skipping, $output is newer than 1gramsbyfreq.txt" >&2
	continue
    fi
	
    # Set LANG so we don't get unicode characters as alphabetic. 
    LANG=C grep -i '^[a-z]*[aeiouy][a-z]*\s' 1gramsbyfreq.txt > "$tempfile"

    if [[ -s "stopwords.txt" ]]; then
	echo "    Removing stopwords using 'stopwords.txt'"
	grep -i -x -v -f stopwords.txt "$tempfile" >"${tempfile}2"
	mv "${tempfile}2" "$tempfile"
    fi

    echo "    Pruning to first 65536 words actually found in dictionary $dict.">&2
    # Note that we explicitly want the headword, not inflections of a word.
    # For example, we want "University" but not "Universities".
    count=0
    cat "$tempfile" | while read word wordcount; do
	if dict -h localhost -d $dict -s exact -m "$word" >/dev/null 2>&1; then
	    echo "$word $wordcount"
	    count=$((count+1))
	fi
	total=$((total+1))
	if [[ $(($total % 1000)) -eq 0 ]]; then
	    tput el1 >&2
	    printf "\r$total: found $count. Current: $word $wordcount">&2
	fi
	if [[ $count -ge 65536 ]]; then break; fi
    done >$output
done
shopt -s nullglob
if [[ -z "$(echo alpha1gramsbyfreq-*.txt)" ]]; then
    echo "No pruned files created. Aborting." >&2
    echo "Maybe you need to 'apt install dictd dict-wn dict-gcide'?"  >&2
    exit 1
fi

# Now make a pretty version, showing percentage and accumulation.
echo "PHASE 5: Creating prettified version with cumulative percentage." >&2
set -- subphase {a..z}
for unpretty in alpha1gramsbyfreq-*.txt; do
    suffix=${unpretty#alpha1gramsbyfreq-}
    pretty=frequency-alpha-$suffix
    shift
    echo "PHASE 5$1: Prettifying $unpretty into $pretty" >&2

    if [[ -s "$pretty" && "$pretty" -nt "$unpretty" ]]; then
	echo "    Skipping prettification as $pretty is newer." >&2
    else
	echo -n "    Finding total usage of words... " >&2
	totalwords=$(awk '{sum+=$2} END{print sum}' < $unpretty)
	printf "%'d\n" "$totalwords" >&2
	echo -n "    Accumulating percentages for each word, saving in $pretty" >&2
	cat $unpretty | awk -v tick="'" -v totalwords=$totalwords '
    BEGIN {
      printf( "#%-9s %-20s\t%14s\t%12s\t%12s\n", 
	      "RANKING", "WORD", "COUNT", "PERCENT", "CUMULATIVE" );
    }
    {
      percent=100*$2/totalwords; 
      cum+=percent; 
      printf( "%-10s %-20s\t%"tick"14d\t%12f%%\t%12f%%\n", NR, $1, $2, percent, cum );
    }
    END { print "."  >"/dev/stderr"; }
    ' > $pretty
    fi
done


echo "All done." >&2
