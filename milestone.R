
library(tm)
library(slam)


dataset.recurse <- function (indir, outdir, func) {
    files <- list.files(indir);
    for (file in files) {
        fn <- paste(indir, "/", file, sep = "")
        info <- file.info(fn) 
        if (info$isdir) {
            od <- paste(outdir, "/", file, sep="");
            dataset.recurse(fn, od, func)
            func(fn, od);
        } else {
            func(indir, outdir, file)
        }
    }
}

######################

dataset.getstat.unique <- function(indir, outdir, file=NULL) {
    
    do.it <- is.null(file) && (length(list.files(path=indir, pattern="*.txt*")) > 0) 
    #print(paste(indir, outdir, file, do.it, sep=", "))    
    if (do.it) {        
        #tr 'A-Z' 'a-z' < file | tr -sc 'A-za-z' '\n'| sort | uniq | wc -l
        #cat %1 | tr 'A-Z' 'a-z'| tr -sc 'A-za-z' '\n'| sort | uniq | wc -l
        wc.uniquewords <- data.frame(file=c(), words=c())
        for (f in list.files(path=indir, pattern="*.txt*")) {
            #above command gave me errors (using cygwin on windows) so i created a 
            #batch file unique_word_count with the following content:
            #@cat %1 | tr 'A-Z' 'a-z'| tr -sc 'A-Za-z' '\n'| uniq | wc -l
            cmd <- paste("unique_word_count ", indir, "/", f, sep="")
            #print(cmd)
            wc.out <- system(cmd, intern=TRUE)
            #print(wc.out)
            wc.uniquewords <- rbind(wc.uniquewords, 
                                    data.frame(file=paste(indir,"/", f, sep=""), 
                                               unique=as.integer(wc.out))) 
        }
    }
    wc.uniquewords
}

dataset.getstat <- function(indir, outdir, file=NULL) {
    do.it <- is.null(file) && (length(list.files(path=indir, pattern="*.txt*")) > 0) 
    #print(paste(indir, outdir, file, do.it, sep=", "))    
    if (do.it) {
        lwc <- system(paste("wc -lwc ", indir,"/*.txt*", sep=""), intern=TRUE)
        lwc <- gsub("(\\d+)\\s*(\\d+)\\s*(\\d+)\\s*(.*)$", "\\1,\\2,\\3,\\4", 
                    lwc, perl=TRUE, ignore.case=TRUE)
        con <- textConnection(lwc)
        lwc <- read.csv(con, header=FALSE, col.names=c("lines", "words", "bytes", "file"))
        close(con)
        lwc <- lwc[-nrow(lwc), ]
        #print(lwc)
        
        unq <- dataset.getstat.unique(indir, outdir, file)
        #print(unq)
        
        stat <- merge(lwc, unq);
        stat$ratio <- round(unq$unique / lwc$words, digits = 4) * 100
        #print(stat)
        
        stat <- stat[, c(1, 2, 3, 5, 6, 4)] #file, lines, words, unique, ratio, bytes
        #print(stat)
        
        if (exists("dataset.stat")) {
            stat <- rbind(dataset.stat, stat)
        }         
        #print(lwurc)
        dataset.stat <<- stat
    }    
}

get_dataset_stats <- function(base) {
    dataset.recurse(base, NULL, dataset.getstat)
    stat <- dataset.stat
    rm("dataset.stat", pos=.GlobalEnv)
    stat    
}

######################

dataset.partition <-function(indir, outdir, file) {
    #print(paste(indir, outdir, file, sep=", "))    
    if (!file.exists(outdir)) {
        dir.create(outdir, recursive=TRUE)
    }
    
    fn.full <- paste(indir,"/", file, sep="")
    
    #40% train 60% rest - Do 5% for now to get small file sizes
    p.train <- 0.05 
    p.cv <- 0.50; p.test <- 0.50 #50-50 of remaining 60%
    
    #gawk 'BEGIN {srand()} {f = FILENAME (rand() <= 0.8 ? ".80" : ".20"); print >f}' en_US.blogs.txt
    cmd <- paste("gawk 'BEGIN {srand()} {f = ", 
                 "FILENAME (rand() <= ", as.character(p.train), " ? \".train\" : \".rest\"); print >f}' ",
                 fn.full, sep="")
    system(cmd)
    
    cmd <- paste("gawk 'BEGIN {srand()} {f = ", 
                 "FILENAME (rand() <= ", as.character(p.cv), " ? \".cv\" : \".test\"); print >f}' ",
                 fn.full, ".rest", sep="")
    system(cmd)
    
    file.rename(paste(fn.full, ".train", sep=""), paste(outdir, "/", file, ".train", sep=""))
    file.rename(paste(fn.full, ".rest.cv", sep=""), paste(outdir, "/", file, ".cv", sep=""))
    file.rename(paste(fn.full, ".rest.test", sep=""), paste(outdir, "/", file, ".test", sep="")) 
    file.remove(paste(fn.full, ".rest", sep=""))    
}

dataset.create <- function (indir, outdir, file=NULL) {
    if (!file.exists(outdir)) {
        dir.create(outdir, recursive=TRUE)
    }
    #print(paste(paste(indir, outdir, file), 
    #            " is.null=", is.null(file), 
    #            " grep .txt=", grepl(".txt$", if(is.null(file)) "a" else file, ignore.case=TRUE), 
    #            sep=''))
    if ((!is.null(file) && grepl(".txt$", file, ignore.case=TRUE))) {
        dataset.partition(indir, outdir, file)
    }
    0
}

get_dataset <- function(outdir) {
    if (!file.exists(outdir)) {
        if (!file.exists("Coursera-SwiftKey.zip")) {
            download.file("https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip",
                          "Coursera-SwiftKey.zip", mode="wb")
            unzip("Coursera-SwiftKey.zip")
        }
        
        if (!file.exists("profanity.txt")) {
            download.file("https://gist.github.com/ryanlewis/a37739d710ccdb4b406d",
                          "profanity.txt", mode="wt")
        }    
        dataset.recurse("Coursera-SwiftKey/final/",
                        outdir,
                        dataset.create)
    }
}
###########################
###########################

library("RWeka")
library("tm")

#profanity obtained from https://gist.github.com/ryanlewis/a37739d710ccdb4b406d

make_ngram_table <- function (file, ngram, lang="en") {

    p1 <- proc.time()
    if (!exists("profanity")) {
        profanity <<- readLines("profanity.txt")
    }
    dat <- readLines(file)
    corp <- Corpus(VectorSource(dat),
                   readerControl = list(reader=readPlain, 
                                        language=lang, 
                                        load=TRUE)
                   #, dbControl = list(useDb = TRUE, dbName = "./nlpdb.db", type="DB1"
    )    
    tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = ngram, max = ngram))
    tdm <- TermDocumentMatrix(corp, control = list(
        tokenize = tokenizer, 
        tolower = TRUE,
        removeWords = profanity,
        
        removePunctuation = TRUE,
        stopwords = TRUE,
        removeNumbers = TRUE,
        stripWhitespace = TRUE))
    
    #print(proc.time() - p1)
    tdm
}

do_milestone <- function() {
    ds <- get_dataset("data.05")
    if (!exists("ds.linecount")) ds.linecount <- get_dataset_lines("Coursera-SwiftKey/final")
    if (!exists("ds.wordcount")) ds.wordcount <- get_dataset_words("Coursera-SwiftKey/final")
    
    print(ds.linecount)
    print(ds.wordcount)
    
    if (!exists("en.blogs.1grams")) en.blogs.1grams <- make_ngram_table("data.05/en_US/en_US.blogs.txt.train", 1)
    if (!exists("en.blogs.2grams")) en.blogs.2grams <- make_ngram_table("data.05/en_US/en_US.blogs.txt.train", 2)
    if (!exists("en.blogs.3grams")) en.blogs.3grams <- make_ngram_table("data.05/en_US/en_US.blogs.txt.train", 3)
    
    if (!exists("en.twitter.1grams")) en.twitter.1grams <- make_ngram_table("data.05/en_US/en_US.twitter.txt.train", 1)
    if (!exists("en.twitter.2grams")) en.twitter.2grams <- make_ngram_table("data.05/en_US/en_US.twitter.txt.train", 2)
    if (!exists("en.twitter.3grams")) en.twitter.3grams <- make_ngram_table("data.05/en_US/en_US.twitter.txt.train", 3)
    
    if (!exists("en.news.1grams")) en.news.1grams <- make_ngram_table("data.05/en_US/en_US.news.txt.train", 1)
    if (!exists("en.news.2grams")) en.news.2grams <- make_ngram_table("data.05/en_US/en_US.news.txt.train", 2)
    if (!exists("en.news.3grams")) en.news.3grams <- make_ngram_table("data.05/en_US/en_US.news.txt.train", 3)
    
    #work               user    system  elapsed 
    #en.blogs.1grams    131.21   42.82  174.87 
    #en.blogs.2grams    158.59   43.87  203.27 
    #en.blogs.3grams    196.60   42.74  240.28 
    #en.twitter.1grams  356.60  112.33  470.77 
    #en.twitter.2grams  365.90  112.77  480.64 
    #en.twitter.3grams  396.31  112.69  509.99 
    #en.news.1grams     156.26   48.74  205.89 
    #en.news.2grams     183.62   48.34  232.95
    #en.news.3grams     210.54   50.61  261.91

}


freq_ngrams <- function(tdm, limit, title) {
    tdm <- rollup(tdm, 2, na.rm=TRUE, FUN = sum)
    freq <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)
    freq <- data.frame(word=names(freq), freq=freq)
    if (!is.null(limit)) {
        freq <- freq[1:limit, ]        
    }
    if (!is.null(title)) {
        title <- if (!is.null(limit)) paste("Top", limit, title) else title
        bp <- barplot(freq$freq, main=title, 
                      horiz=TRUE,
                      names.arg=c(as.character(freq$word)), cex.names=0.8, las=1)
    }
    #f <- list(freq=freq, plot = bp);
    bp
    freq
}


