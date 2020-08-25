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
# * consist of only lowercase letters, no number, symbols or capitalization.
# * must have at least one vowel
# * no curse words or other stop words ("et" "al" "y" "de" "le" "des" "un" "von" "di")
# * must occur more than 100,000 times in the corpus
# * must appear in WordNet or Websters1913
echo "PHASE 4: Now extracting alphabetic words with vowels to alpha1gramsbyfreq.txt" >&2
if [[ "alpha1gramsbyfreq.txt" -nt "1gramsbyfreq.txt" ]]; then
    echo "Skipping alpha extraction, alpha1gramsbyfreq.txt is newer than 1gramsbyfreq.txt" >&2
else
    # Set LANG so we don't get unicode characters as alpha
    LANG=C grep '^[a-z]*[aeiouy][a-z]*\s' 1gramsbyfreq.txt > "$tempfile"

    if [[ -s "stopwords.txt" ]]; then
	echo "Removing stopwords using stopwords.txt"
	grep -x -v -f stopwords.txt "$tempfile" >"${tempfile}2"
	mv "${tempfile}2" "$tempfile"
    fi

    echo "Pruning to first 65536 words actually found in the dictionary.">&2
    # Note that we explicitly want the headword, not inflections of a word.
    # For example, I want "nincompoop" but not "nincompoops"
    count=0
    cat "$tempfile" | while read word wordcount; do
			  if dict -d wn -s exact -m "$word" >/dev/null 2>&1; then
			      echo "$word $wordcount"
			      count=$((count+1))
			  fi
			  total=$((total+1))
			  if [[ $(($total % 1000)) -eq 0 ]]; then
			      tput el1 >&2
			      printf "\r$total: found $count. Current: $word $wordcount">&2
			  fi
			  if [[ $count -ge 65536 ]]; then break; fi
		      done >alpha1gramsbyfreq.txt

fi


# Now make a pretty version, showing percentage and accumulation.
echo "PHASE 5: Creating prettified version, frequency-alpha.txt" >&2

if [[ "frequency-alpha.txt" -nt "alpha1gramsbyfreq.txt" ]]; then
    echo "Skipping prettification. frequency-alpha.txt is newer than alpha1gramsbyfreq.txt" >&2
else
    echo -n "Finding total words... " >&2
    totalwords=$(awk '{sum+=$2} END{print sum}' < alpha1gramsbyfreq.txt)
    printf "%'d\n" "$totalwords" >&2

    echo -n "Accumulating percentages for each word, saving in frequency-alpha.txt" >&2
    cat alpha1gramsbyfreq.txt | awk -v tick="'" -v totalwords=$totalwords '
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
    ' > frequency-alpha.txt
fi



echo "All done." >&2




