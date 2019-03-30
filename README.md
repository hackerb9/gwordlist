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

While there are technically a little under a trillion "words" in the
corpus, it's a mistake to think you'll find a trillion *different* or
even *useful* words. For example, of those trillion, 6% of them are a
single comma. Google used completely automated OCR techniques to find
the words and it made a lot of mistakes. Moreover, their definition of
a word includes things like `s`, `A4oscow`,
`IIIIIIIIIIIIIIIIIIIIIIIIIIIII`, `cuando`, `aro`,
`ihm`,`SpecialMarkets@ThomasNelson`, `buisness`[sic], and `,`. To
compensate, they only included words in the corpus that appeared at
least 40 times, but even so there's so much dreck at the bottom of the
list that it's really not worth bothering. Personally, I found that
words that appeared over 100,000 times tended to be worthwhile.
In addition, I was getting so many obvious OCR errors that I
decided to also create some cleaner lists by using
[dict](http://dict.org) to check every word against a dictionary.
(IMPORTANT NOTE! If you run these scripts, be sure to setup your own
dictd so you're not pounding the internet servers for a bazillion
lookups.) After pruning with dictionaries, I found 65536 words seemed
like a more reasonable number to cutoff.

## How big are the files? 

If you run my scripts (which are tiny) they
will download about 5.4GiB of data from Google. However, if you simply
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
