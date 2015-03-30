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


<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Sun Mar 29 20:44:46 2015 -->
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

<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Sun Mar 29 20:44:46 2015 -->
<table border=1>
<tr> <th>  </th> <th> Type </th> <th> Project </th> <th> Report </th>  </tr>
  <tr> <td align="right"> 1 </td> <td> Training % </td> <td align="right"> 60.00 </td> <td align="right"> 5.00 </td> </tr>
  <tr> <td align="right"> 2 </td> <td> CV % </td> <td align="right"> 20.00 </td> <td align="right">  </td> </tr>
  <tr> <td align="right"> 3 </td> <td> Test % </td> <td align="right"> 20.00 </td> <td align="right">  </td> </tr>
   </table>

Thus the English training data for this report looks as follows:

<!-- html table generated in R 3.1.3 by xtable 1.7-4 package -->
<!-- Sun Mar 29 20:44:46 2015 -->
<table border=1>
<tr> <th>  </th> <th> File </th> <th> Lines (mil) </th> <th> Words (mil) </th> <th> Unique (mil) </th> <th> % Unique </th> <th> Bytes (MB) </th>  </tr>
  <tr> <td align="right"> 1 </td> <td> en.blogs cv </td> <td align="right"> 0.43 </td> <td align="right"> 17.74 </td> <td align="right"> 0.18 </td> <td align="right"> 1.00 </td> <td align="right"> 99.61 </td> </tr>
  <tr> <td align="right"> 2 </td> <td> en.blogs test </td> <td align="right"> 0.43 </td> <td align="right"> 17.68 </td> <td align="right"> 0.18 </td> <td align="right"> 1.00 </td> <td align="right"> 99.23 </td> </tr>
  <tr> <td align="right"> 3 </td> <td> en.blogs train </td> <td align="right"> 0.04 </td> <td align="right"> 1.85 </td> <td align="right"> 0.06 </td> <td align="right"> 3.26 </td> <td align="right"> 10.42 </td> </tr>
  <tr> <td align="right"> 4 </td> <td> en.news cv </td> <td align="right"> 0.48 </td> <td align="right"> 16.34 </td> <td align="right"> 0.16 </td> <td align="right"> 0.96 </td> <td align="right"> 97.50 </td> </tr>
  <tr> <td align="right"> 5 </td> <td> en.news test </td> <td align="right"> 0.48 </td> <td align="right"> 16.26 </td> <td align="right"> 0.16 </td> <td align="right"> 0.96 </td> <td align="right"> 97.09 </td> </tr>
  <tr> <td align="right"> 6 </td> <td> en.news train </td> <td align="right"> 0.05 </td> <td align="right"> 1.71 </td> <td align="right"> 0.06 </td> <td align="right"> 3.49 </td> <td align="right"> 10.20 </td> </tr>
  <tr> <td align="right"> 7 </td> <td> en.twitter cv </td> <td align="right"> 1.12 </td> <td align="right"> 14.39 </td> <td align="right"> 0.20 </td> <td align="right"> 1.38 </td> <td align="right"> 78.14 </td> </tr>
  <tr> <td align="right"> 8 </td> <td> en.twitter test </td> <td align="right"> 1.12 </td> <td align="right"> 14.42 </td> <td align="right"> 0.20 </td> <td align="right"> 1.38 </td> <td align="right"> 78.31 </td> </tr>
  <tr> <td align="right"> 9 </td> <td> en.twitter train </td> <td align="right"> 0.12 </td> <td align="right"> 1.53 </td> <td align="right"> 0.06 </td> <td align="right"> 3.79 </td> <td align="right"> 8.29 </td> </tr>
   </table>

## Data Analysis

The 1-gram, 2-gram and 3-gram for Blogs, Twitter and News are as follows:
![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-1.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-2.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-3.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-4.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-5.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-6.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-7.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-8.png) ![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-9.png) 


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
