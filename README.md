# gwordlist
This project includes wordlists derived from [Google's ngram corpora](http://books.google.com/ngrams/) plus the programs used to automatically download and derive the lists, should you so wish. 

## What does the data look like?

Here's a sample of one of the files:

    #RANKING   WORD                          COUNT       PERCENT      CUMULATIVE
    1          ,                    55,914,692,931      6.252008%       6.252008%
    2          the                  53,097,503,134      5.937009%      12.189017%
    3          of                   30,966,277,550      3.462443%      15.651460%
    4          and                  22,631,938,946      2.530553%      18.182013%
    5          to                   19,347,658,561      2.163326%      20.345339%

Interestingly, if this data is right, only five words make up 20% of all the words in books from 1880 to 2000. And one of those "words" is a comma! (Don't believe comma is a word? I've also created wordlists that exclude punctuation.)

## Why does this exist?
I needed my [XKCD 936]() compliant [password generator](https://github.com/hackerb9/mkpass) to have a good list of words in order to make memorable passphrases. Most lists I've seen are not terribly good for my purposes as the words are often from extremely narrow domains. The best I found was [SCOWL](), but I didn't like that the words weren't sorted by frequency so I couldn't easily take a slice of, say, the top 4096 most frequent words.

The obvious solution was to use Google's ngram corpus which claims to have a trillion different words pruned from all the books they've scanned for books.google.com (about 4% of all books ever published, they say). Unfortunately, while some people had posted small lists, nobody had the entire list of every word sorted by frequency. So, I made this and here it is.

## What can this data be used for?
Anything you want. While my programs are licensed under the GNU GPL ≥3, I'm explicitly releasing the data produced under the same license as Google granted me: Creative Commons Attribution 3.0. 

## How many words does it *really* have? 

There are 37,235,985 entries in the V3 (20200217) corpus, but it's a
mistake to think there are 37 million *different*, *useful* words. For
example, 6% of the words are a single comma. Google used completely
automated OCR techniques to find the words and it made a lot of
mistakes. Moreover, their definition of a “word” includes things like
`s`, `A4oscow`, `IIIIIIIIIIIIIIIIIIIIIIIIIIIII`, `cuando`, `لاامش`,
`ihm`,`SpecialMarkets@ThomasNelson`, `buisness`[sic], and `,`. To
compensate, they only included words in the corpus that appeared at
least 40 times, but even so there's so much dreck at the bottom of the
list that it's really not worth bothering. Personally, I found that
words that appeared over 100,000 times tended to be worthwhile. In
addition, I was getting so many obvious OCR errors that I decided to
also create some cleaner lists by using [dict](http://dict.org) to
check every word against a dictionary. (IMPORTANT NOTE! If you run
these scripts, be sure to setup your own dictd so you're not pounding
the internet servers for a bazillion lookups.) After pruning with
dictionaries, I found 65536 words seemed like a more reasonable number
to cutoff.

## How big are the files? 

If you run my scripts (which are tiny) they
will download about 14GiB of data from Google. However, if you simply
want [the final
list](https://github.com/hackerb9/gwordlist/blob/master/1gramsbyfreq.txt.gz),
it is about 100MB, uncompressed. Alternately, if you don't need so
much, consider downloading one of the smaller files I created that
have been cleaned up and limited to only the top words, such as
[frequency-alpha-gcide.txt](https://github.com/hackerb9/gwordlist/blob/master/frequency-alpha-gcide.txt).

## What got thrown away in these subcopora?
As you can guess, since the file size went down by 90%, I tossed a lot of info. The biggest changes were from losing the separate counts for each year, ignoring the tags for parts of speech (e.g., I merged watch_VERB with watch_NOUN), and from combining different capitalization into a single term. (Each word is listed under its most frequent capitalization: for example, "London", instead of "london".) If you need that data, it's not hard to modify the scripts. Let me know if you have trouble.

## What got added?
I counted up the total number of words in all the books so I could get a rough percentage of how often each word was being used in English. I also include a running total of the percentage so you can truncate the file wherever you want. (E.g., to get a list of 95% of all words used in English). 

## Bugs

* Script cannot run on a 32-bit machine as it briefly requires more
  than 4GiB of RAM as it makes a hashtable of every word.

## Old Notes

* I may need a manually created "stopword" list due to all the
  obviously non-English words appearing in the list.

* Some of the 1-grams I'm turning up as quite popular should actually
  be 2-grams: e.g. York -> New York. Maybe I should add in 2-grams to
  the list, since some of them will clearly be in the list of most
  common "words".

* Some words *should* be capitalized, such as "I" and "London".
  But it makes sense to accumulate "the" and "The", since otherwise
  both will be listed as one of the most common words.

  Solution: Accumulate twice. First time case-sensitive. Sort by
  frequency. Then, second time, case-insensitive, outputting the
  *first* variation found. 


* I'm currently getting some very strange results, or at least
  unexpected, results.  While the 100 words seem reasonably common,
  there are some strangely highly ranked words:

	124 s
	147 p
	151 J
	165 de
	202 M
	209 general
	214 B
	225 S
	226 Mr
	228 York
	238 D
	241 government
	254 R
	272 et
	282 E
	291 John
	292 University
	294 U
	309 H
	325 P
	328 pp
	359 English
	365 L
	371 v
	373 London
	390 W
	391 Fig
	399 e
	405 F
	422 Figure
	426 G
	444 British
	445 T
	446 c
	455 N
	466 II
	472 b
	478 French
		479 England
	508 St
	509 General

Compare that with common words that are found much less frequently:

	2124 eat
	4004 TV
	6040 ate
	6041 bedroom
	6138 fool
	10007 foul
	10012 swim
 	10017 sore
	15013 lone
	15020 doom
	


* Am I adding things up correctly? The least amount of times any word
  is found is 40. Was that a cut off when they were creating the
  corpus, presuming words that showed up less than that were OCR
  errors?


* There are a bunch of nonsense/units/foreign words mixed in to this
 corpus. How can I get rid of them all easily?

** Maybe I can get a list of unit abbreviations and grep them out?

      lbs, J, gm, ppm

** Maybe look up words in gcide and reject non-existent words? OED is too liberal.

   cuando, aro, ihm

** A lot of the words that are of type "_X" are suspicious and there's
   only 159 of them in the over-1E6 list.

*** Some are not in WordNet and can be easily discarded:

    et dem bei durch deux der per je ibid wird und auf su comme lui que ch
    della hoc quam del ou auch bien cette les zur sont seq ont du che
    facto leur nur di una einer entre ich op sich avec um mais qui nicht
    inasmuch zum peut dans por ah vel quae los eine vous esse sunt im quod
    nach como une ein aux wie ist lo sie fait las aus werden dei

*** However, that still leaves 83 that are not as easy:

    de e el il au r u tout hell esp b d est sur iv pas sa nous ni z la f
    se in das chap fig er oder des ii iii m mit als dear alas ma c le o h
    ex para j vii mi no yes den x oh vi ut bye mm en die l zu v well pro w
    ab al un si ne ce es k cf viii i y non ad g cum ha sind te

*** Most of the real words ("well", "hell", "dear", "chap", "no",
    "den", "die", show up as
    other types of speech. On the other hand, words like "bye", "yes",
    and "alas" are definitely words, and they're not listed under any
    other type than _X. (What does _X mean? Interjection?)

* At first I tried accumulating a different count for each usage of a
  word (e.g., watch_VERB and watch_NOUN), but that meant some words
  wouldn split their vote and not be listed among the most common.
  Also, it meant I had many duplicates of the same word. So, I now I
  just throwaway the part of speech.
  	       
  r_ADP   1032605				out_ADV 9199818
  r_CONJ  1048981				out_ADJ 8645123
  r_PRON  1019601				out_PRT 332451517
  r_NUM   3316486				out_NOUN        4462386
  r_X     3125051				out_ADP 159492310
  r_NOUN  2975438
  r_VERB  2931183
  r_PRT   1044181
  r_ADJ   2327691

* There are 117 words with no vowels, none of them real words.
  grep '^[^aeiouy]*_' foo

* Some words are contractions:

	cit_NOUN (webster says it means citizen, but given how
		 commonly used it is, more often than "dogs", maybe it
		 was for citations?)

* Some words make no sense whatsoever to me:

        eds_NOUN	12084339

* Some words are british:

	programme


* If I had some way to accumulate words to their lemmas ("head word"),
  that would maybe allow me to accumulate them so they'll make the 1E6
  threshold of useful words: (watching, watches, watched, -> watch)

** Perhaps dict using wordnet? No. Websters? Sort of. It works for
  'watching'->'watch', but not 'dogs' -> 'dog'.

* There are some odd orderings. How can "go" be less common than
  "children"?
  
* Some words appear to be misspellings.

  buisness

* Some words may be misspellings or OCR problems.

  ADJOURNMEN, ADMINISTATION, bonjamin, Buddhisn

* Some words are clearly OCR errors, not misspellings in the original

  A1most, A1ways, A1uminum, a1titude
  A1nerica, A1nerican
  ADMlNlSTRATlON, LlBRARY, lNSTANT, lNTERNAL, LlVED, lDEAS, lNVERSE, lRELAND
  lNTRODUCTlON, lNlTlAL, lNTERlM, (and on and on...)
  areheology
  anniverfary
  beingdeveloped    
  A0riculture, A0erage, 0paque, 0ndustry, 1nch
  A9riculture, a9ain, a9ainst, a9ent, a9ked, 
  Aariculture
  AAppppeennddiixx
  Thmking
  A4oscow (should be "Moscow")
  
* Some words have been mangled by Google on purpose:

	can't, cannot -> "can not" (bigram)

* List of Part of Speech tags (from books.google.com/ngrams/info)
  _NOUN_
  _VERB_
  _ADJ_		adjective
  _ADV_		adverb
  _PRON_	pronoun
  _DET_		determiner or article
  _ADP_		an adposition: either a preposition or a postposition
  _NUM_ 	numeral
  _CONJ_	conjunction
  _PRT_		particle

* Google uses these tags for searching, but they don't appear (at least in 1-grams):
  _ROOT_	root of the parse tree	These tags must stand alone (e.g., _START_)
  _START_	start of a sentence
  _END_		end of a sentence

* Google does not document the _X tag

* List of Corpora (from books.google.com/ngrams/info)

  Informal corpus name   Shorthand         Persistent identifier
  ==============================================================
  American English 2012  eng_us_2012       googlebooks-eng-us-all-20120701
  American English 2009  eng_us_2009       googlebooks-eng-us-all-20090715
			 Books predominantly in the English language
			 that were published in the United States.

  British English 2012   eng_gb_2012       googlebooks-eng-gb-all-20120701
  British English 2009   eng_gb_2009       googlebooks-eng-gb-all-20090715
			 Books predominantly in the English language
			 that were published in Great Britain.

  English 2012           eng_2012          googlebooks-eng-all-20120701
  English 2009           eng_2009          googlebooks-eng-all-20090715
			 Books predominantly in the English language
			 published in any country.

  English Fiction 2012   eng_fiction_2012  googlebooks-eng-fiction-all-20120701
  English Fiction 2009   eng_fiction_2009  googlebooks-eng-fiction-all-20090715
			 Books predominantly in the English language
			 that a library or publisher identified as
			 fiction.

  English One Million    eng_1m_2009       googlebooks-eng-1M-20090715
			 The "Google Million". All are in English with
			 dates ranging from 1500 to 2008. No more than
			 about 6000 books were chosen from any one year,
			 which means that all of the scanned books from
			 early years are present, and books from later
			 years are randomly sampled. The random
			 samplings reflect the subject distributions for
			 the year (so there are more computer books in
			 2000 than 1980).

