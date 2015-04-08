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
The data was obtained from the link https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip, which is provided by the course instructures. The zip contains copora of blogs, news and twitter in 4 languages English, Dutch, French and Russian. The statistics of the combined corpous is as follows: 


```r
source("milestone.R")
library(xtable)
```


```r
if (!exists("ds.stat")) {
    dss <- get_dataset_stats("Coursera-SwiftKey/final")
    dss$file <- gsub("Coursera-Swiftkey/final/.*/(..)_..(.*).txt", "\\1\\2",
                     as.character(dss$file), perl=TRUE, ignore.case=TRUE)
    dss[, c(2,3,4,6)] <- round(dss[, c(2,3,4,6)] / 1000000, digits = 4)
    names(dss) <- c("File", "Lines (mil)", "Words (mil)",
                    "Unique (mil)", "% Unique", "Bytes (MB)") 
    ds.stat <<- dss
} 
```
<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Tue Apr 07 17:38:31 2015 -->
<table border=1>
<tr> <th>  </th> <th> File </th> <th> Lines (mil) </th> <th> Words (mil) </th> <th> Unique (mil) </th> <th> % Unique </th> <th> Bytes (MB) </th>  </tr>
  <tr> <td align="right"> 1 </td> <td> de.blogs </td> <td align="right"> 0.37 </td> <td align="right"> 12.61 </td> <td align="right"> 0.39 </td> <td align="right"> 3.06 </td> <td align="right"> 85.46 </td> </tr>
  <tr> <td align="right"> 2 </td> <td> de.news </td> <td align="right"> 0.24 </td> <td align="right"> 13.20 </td> <td align="right"> 0.38 </td> <td align="right"> 2.88 </td> <td align="right"> 95.59 </td> </tr>
  <tr> <td align="right"> 3 </td> <td> de.twitter </td> <td align="right"> 0.95 </td> <td align="right"> 11.79 </td> <td align="right"> 0.32 </td> <td align="right"> 2.75 </td> <td align="right"> 75.58 </td> </tr>
  <tr> <td align="right"> 4 </td> <td> en.blogs </td> <td align="right"> 0.90 </td> <td align="right"> 37.27 </td> <td align="right"> 0.25 </td> <td align="right"> 0.68 </td> <td align="right"> 210.16 </td> </tr>
  <tr> <td align="right"> 5 </td> <td> en.news </td> <td align="right"> 1.01 </td> <td align="right"> 34.31 </td> <td align="right"> 0.21 </td> <td align="right"> 0.62 </td> <td align="right"> 205.81 </td> </tr>
  <tr> <td align="right"> 6 </td> <td> en.twitter </td> <td align="right"> 2.36 </td> <td align="right"> 30.34 </td> <td align="right"> 0.30 </td> <td align="right"> 1.00 </td> <td align="right"> 167.11 </td> </tr>
  <tr> <td align="right"> 7 </td> <td> fi.blogs </td> <td align="right"> 0.44 </td> <td align="right"> 12.71 </td> <td align="right"> 0.87 </td> <td align="right"> 6.81 </td> <td align="right"> 108.50 </td> </tr>
  <tr> <td align="right"> 8 </td> <td> fi.news </td> <td align="right"> 0.49 </td> <td align="right"> 10.41 </td> <td align="right"> 0.68 </td> <td align="right"> 6.54 </td> <td align="right"> 94.23 </td> </tr>
  <tr> <td align="right"> 9 </td> <td> fi.twitter </td> <td align="right"> 0.29 </td> <td align="right"> 3.15 </td> <td align="right"> 0.30 </td> <td align="right"> 9.49 </td> <td align="right"> 25.33 </td> </tr>
  <tr> <td align="right"> 10 </td> <td> ru.blogs </td> <td align="right"> 0.34 </td> <td align="right"> 2.04 </td> <td align="right"> 0.02 </td> <td align="right"> 0.99 </td> <td align="right"> 116.86 </td> </tr>
  <tr> <td align="right"> 11 </td> <td> ru.news </td> <td align="right"> 0.20 </td> <td align="right"> 1.80 </td> <td align="right"> 0.01 </td> <td align="right"> 0.54 </td> <td align="right"> 119.00 </td> </tr>
  <tr> <td align="right"> 12 </td> <td> ru.twitter </td> <td align="right"> 0.88 </td> <td align="right"> 2.42 </td> <td align="right"> 0.02 </td> <td align="right"> 0.91 </td> <td align="right"> 105.18 </td> </tr>
   </table>

## Data Preparation

We will primarily work with English dataset. Working with full English dataset took long time for the desktop computer. So we decided to break the data into a smaller set for this report: 


```r
breakdown = list(train=60, cv=20, test=20)
xt <- xtable(data.frame(Type=c("Training %", "CV %", "Test %"),
                        Project=unlist(breakdown), Report=c(5, NA, NA)))
```
<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Tue Apr 07 17:38:31 2015 -->
<table border=1>
<tr> <th>  </th> <th> Type </th> <th> Project </th> <th> Report </th>  </tr>
  <tr> <td align="right"> train </td> <td> Training % </td> <td align="right"> 60.00 </td> <td align="right"> 5.00 </td> </tr>
  <tr> <td align="right"> cv </td> <td> CV % </td> <td align="right"> 20.00 </td> <td align="right">  </td> </tr>
  <tr> <td align="right"> test </td> <td> Test % </td> <td align="right"> 20.00 </td> <td align="right">  </td> </tr>
   </table>

Thus the English training data for this report looks as follows:

```r
train.dir <- sprintf("data.%02d", breakdown$train)
ds <- get_dataset(train.dir, breakdown)

if (!exists("ds.prep.stat")) {
    dps <- get_dataset_stats(train.dir)
    dps$file <- gsub(paste0(train.dir,"/.*/(..)_..(.*).txt.(.*)"), "\\1\\2 \\3",
                     as.character(dps$file),
                     perl=TRUE, ignore.case=TRUE)
    dps[, c(2,3,4,6)] <- round(dps[, c(2,3,4,6)] / 1000000, digits = 4)
    names(dps) <- c("File", "Lines (mil)", "Words (mil)",
                    "Unique (mil)", "% Unique", "Bytes (MB)")    
    ds.prep.stat <<- dps[grep("^en", dps$File),]
}
```
<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Tue Apr 07 17:38:31 2015 -->
<table border=1>
<tr> <th>  </th> <th> File </th> <th> Lines (mil) </th> <th> Words (mil) </th> <th> Unique (mil) </th> <th> % Unique </th> <th> Bytes (MB) </th>  </tr>
  <tr> <td align="right"> 10 </td> <td> en.blogs cv </td> <td align="right"> 0.18 </td> <td align="right"> 7.46 </td> <td align="right"> 0.12 </td> <td align="right"> 1.57 </td> <td align="right"> 41.85 </td> </tr>
  <tr> <td align="right"> 11 </td> <td> en.blogs test </td> <td align="right"> 0.18 </td> <td align="right"> 7.48 </td> <td align="right"> 0.12 </td> <td align="right"> 1.57 </td> <td align="right"> 42.00 </td> </tr>
  <tr> <td align="right"> 12 </td> <td> en.blogs train </td> <td align="right"> 0.54 </td> <td align="right"> 22.34 </td> <td align="right"> 0.20 </td> <td align="right"> 0.89 </td> <td align="right"> 125.41 </td> </tr>
  <tr> <td align="right"> 13 </td> <td> en.news cv </td> <td align="right"> 0.20 </td> <td align="right"> 6.84 </td> <td align="right"> 0.11 </td> <td align="right"> 1.59 </td> <td align="right"> 40.81 </td> </tr>
  <tr> <td align="right"> 14 </td> <td> en.news test </td> <td align="right"> 0.20 </td> <td align="right"> 6.88 </td> <td align="right"> 0.11 </td> <td align="right"> 1.59 </td> <td align="right"> 41.05 </td> </tr>
  <tr> <td align="right"> 15 </td> <td> en.news train </td> <td align="right"> 0.61 </td> <td align="right"> 20.60 </td> <td align="right"> 0.17 </td> <td align="right"> 0.84 </td> <td align="right"> 122.94 </td> </tr>
  <tr> <td align="right"> 16 </td> <td> en.twitter cv </td> <td align="right"> 0.47 </td> <td align="right"> 6.07 </td> <td align="right"> 0.12 </td> <td align="right"> 2.03 </td> <td align="right"> 32.94 </td> </tr>
  <tr> <td align="right"> 17 </td> <td> en.twitter test </td> <td align="right"> 0.47 </td> <td align="right"> 6.07 </td> <td align="right"> 0.12 </td> <td align="right"> 2.03 </td> <td align="right"> 32.98 </td> </tr>
  <tr> <td align="right"> 18 </td> <td> en.twitter train </td> <td align="right"> 1.42 </td> <td align="right"> 18.20 </td> <td align="right"> 0.23 </td> <td align="right"> 1.25 </td> <td align="right"> 98.82 </td> </tr>
   </table>

## Data Analysis

The 1-gram, 2-gram and 3-gram for Blogs, Twitter and News are as follows:

```r
make_ngrams(train.dir)
```

```r
(freq.en.1grams <<- freq_ngrams(en.1grams, 100, "EN 1-Grams"))$plot
```

![plot of chunk show_ngrams](figure/show_ngrams-1.png) 

```
## NULL
```

```r
(freq.en.2grams <<- freq_ngrams(en.2grams, 100, "EN 2-Grams"))$plot
```

![plot of chunk show_ngrams](figure/show_ngrams-2.png) 

```
## NULL
```

```r
(freq.en.3grams <<- freq_ngrams(en.3grams, 100, "EN 3-Grams"))$plot
```

![plot of chunk show_ngrams](figure/show_ngrams-3.png) 

```
## NULL
```

```r
(freq.en.4grams <<- freq_ngrams(en.4grams, 100, "EN 4-Grams"))$plot
```

![plot of chunk show_ngrams](figure/show_ngrams-4.png) 

```
## NULL
```

```r
(freq.en.5grams <<- freq_ngrams(en.5grams, 100, "EN 5-Grams"))$plot
```

![plot of chunk show_ngrams](figure/show_ngrams-5.png) 

```
## NULL
```


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
