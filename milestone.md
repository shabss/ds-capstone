---
title: "Data Science Captsone Milestone Report"
author: "Shabbir Suterwala"
date: "Sunday, March 29, 2015"
output: html_document
---

# Data Science Captsone Milestone Report
**Shabbir Suterwala**

## Executive Summary
The purpose of this report is to establish an understanding of basic tasks required for data processing of a text corpus. English Blogs, News and Twitter corpora are analyised for word, line and unique word counts. Further more top 1gram, 2grams and 3grams are presented. 

## Data Analysis Level 1
The data was obtained from the link https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip, which provide by course instructures. The zip contains copora of blogs, news and twitter in 4 languages English, Dutch, French and Russian. The statistics of the combined corpous is as follows: 


```r
source("milestone.R")
if (!exists("ds.linecount")) ds.linecount <- get_dataset_lines("Coursera-SwiftKey/final")
if (!exists("ds.wordcount")) ds.wordcount <- get_dataset_words("Coursera-SwiftKey/final")
stat <- merge(ds.wordcount, ds.linecount)
stat$file <- gsub("Coursera-Swiftkey/final/.*/(..)_..(.*).txt", "\\1\\2",
                  as.character(stat$file), perl=TRUE, ignore.case=TRUE)
stat
```

```
##          file     words   unique   lines
## 1    de.blogs  85459666 13490044  371440
## 2     de.news  95591959 14281896  244743
## 3  de.twitter  75578341 12271007  947774
## 4    en.blogs 210160014 37844572  899288
## 5     en.news 205811889 34600499 1010242
## 6  en.twitter 167105338 30506876 2360148
## 7    fi.blogs 108503595 15008275  439785
## 8     fi.news  94234350 12304795  485758
## 9  fi.twitter  25331142  3626100  285214
## 10   ru.blogs 116855835    81704  337100
## 11    ru.news 118996424    48450  196360
## 12 ru.twitter 105182346   144232  881414
```

## Data Preparation

We will primarily work with English dataset. Working with full English dataset took long time for the desktop computer. So we decided to break the data into a smaller set for this report: 


```
##         Type Project Report
## 1 Training %      60      5
## 2       CV %      20     NA
## 3     Test %      20     NA
```

Thus the English training data for this report looks as follows:

```r
#prepare training,cv,test data into data.05 folder. 
#0.5% training data extraction is currently hardcoded
ds <- get_dataset("data.05")
if (!exists("ds.linecount.report")) ds.linecount.report <- get_dataset_lines("data.05")
if (!exists("ds.wordcount.report")) ds.wordcount.report <- get_dataset_words("data.05")
stat <- merge(ds.wordcount.report, ds.wordcount.report)
stat$file <- gsub("data.05/.*/(..)_..(.*).txt.(.*)", "\\1\\2 \\3",
                  as.character(stat$file), perl=TRUE, ignore.case=TRUE)
stat <- stat[grep("^en", stat$file),]
stat
```

```
##                file    words   unique
## 10      en.blogs cv 99614866 18011944
## 11    en.blogs test 99228613 17950281
## 12   en.blogs train 10417247  1882363
## 13       en.news cv 97504067 16473302
## 14     en.news test 97092923 16403108
## 15    en.news train 10204657  1724087
## 16    en.twitter cv 78140493 14470210
## 17  en.twitter test 78312684 14500597
## 18 en.twitter train  8292013  1536001
```

## Data Analysis

The 1-gram, 2-gram and 3-gram for Blogs, Twitter and News are as follows:
![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-1.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-2.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-3.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-4.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-5.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-6.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-7.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-8.png) ![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-9.png) 


## Modeling Strategy

To buld the prediction model following tasks has to be further performed

   1. Use porter stemming to improve N-gram frequencies. This will help reduce data footprint of the model
   2. Use PCFG to understand the sentense structure. This will help with predicting the right POS
   3. Once probable words are found with combining porter stemming and PCFG, Use backoff strategy to predict probability of a given word.
   
## Logistic Strategy

Given the resource requirements for the tm package we will break the training data into multiple pieces and distribute this on multiple machines. Too keep things simple file system will be used as data sharing mechanism. 

   1. Training dataset will equally split into 10 parts. This can easily be done with Linux/Unix utilities.
   2. A total of 4 computers will be used to perform the tasks. Each computer will read the training set from folder that is shared and write the data to the shared folder. Tasks are:
      1. Creating Document Term Matrix for training part N
      2. Creating a merged model from individual models
   3. One master computer will issue the tasks. The master will will also execute tasks.

To reduce the data foot print other NLP smooting methods besides backoff smooting will be analzed and best will be picked
   
# Conclusion
English Blogs, News and Twitter corpora are analyised for word, line and unique word counts and corresponding 1gram, 2grams and 3grams are presented. Additionally, strategies for building a machine learning model to predict the next word is provided.

# References
1. http://nlp.stanford.edu/~wcmac/papers/20050421-smoothing-tutorial.pdf
