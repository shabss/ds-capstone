
library(tm)
library(slam)
library(stringi)

sysname <- toupper(system("uname -n", intern=TRUE))
if (sysname == "USMONSSUTERWA01") {
    Sys.setenv(JAVA_HOME='c:\\jre7_x64')
    options( java.parameters = "-Xmx24g" )
}

dataset.recurse <- function (indir, outdir, func, param) {
    files <- list.files(indir);
    for (file in files) {
        fn <- paste(indir, "/", file, sep = "")
        info <- file.info(fn) 
        if (info$isdir) {
            od <- paste(outdir, "/", file, sep="");
            dataset.recurse(fn, od, func, param)
            func(fn, od, NULL, param);
        } else {
            func(indir, outdir, file, param)
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

dataset.getstat <- function(indir, outdir, file=NULL, param) {
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

dataset.scale.breakdown <- function(breakdown) {
    p.sum <- breakdown$train + breakdown$cv + breakdown$test 
    p.train <- breakdown$train / p.sum 
    p.cv <- breakdown$cv / p.sum
    p.test <- breakdown$cv / p.sum
    
    #scale p.cv and p.test to remaining datase
    p.cv <- p.cv / (1 - p.train)
    p.test <- p.test / ( 1 - p.train)
    list(train=p.train, cv=p.cv, test=p.test)
}

dataset.partition <-function(indir, outdir, file, breakdown) {
    #print(paste(indir, outdir, file, sep=", "))    
    if (!file.exists(outdir)) {
        dir.create(outdir, recursive=TRUE)
    }
    
    fn.full <- paste(indir,"/", file, sep="")
    
    #40% train 60% rest - Do 5% for now to get small file sizes
    bd <- dataset.scale.breakdown(breakdown)
    #gawk 'BEGIN {srand()} {f = FILENAME (rand() <= 0.8 ? ".80" : ".20"); print >f}' en_US.blogs.txt
    cmd <- paste("gawk 'BEGIN {srand()} {f = ", 
                 "FILENAME (rand() <= ", as.character(bd$train), " ? \".train\" : \".rest\"); print >f}' ",
                 fn.full, sep="")
    system(cmd)
    
    cmd <- paste("gawk 'BEGIN {srand()} {f = ", 
                 "FILENAME (rand() <= ", as.character(bd$cv), " ? \".cv\" : \".test\"); print >f}' ",
                 fn.full, ".rest", sep="")
    system(cmd)
    
    file.rename(paste(fn.full, ".train", sep=""), paste(outdir, "/", file, ".train", sep=""))
    file.rename(paste(fn.full, ".rest.cv", sep=""), paste(outdir, "/", file, ".cv", sep=""))
    file.rename(paste(fn.full, ".rest.test", sep=""), paste(outdir, "/", file, ".test", sep="")) 
    file.remove(paste(fn.full, ".rest", sep=""))    
}

dataset.create <- function (indir, outdir, file, breakdown) {
    if (!file.exists(outdir)) {
        dir.create(outdir, recursive=TRUE)
    }
    #print(paste(paste(indir, outdir, file), 
    #            " is.null=", is.null(file), 
    #            " grep .txt=", grepl(".txt$", if(is.null(file)) "a" else file, ignore.case=TRUE), 
    #            sep=''))
    if ((!is.null(file) && grepl(".txt$", file, ignore.case=TRUE))) {
        dataset.partition(indir, outdir, file, breakdown)
    }
}

get_dataset <- function(outdir, breakdown) {
    if (!file.exists(outdir)) {
        if (!file.exists("Coursera-SwiftKey.zip")) {
            download.file("https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip",
                          "Coursera-SwiftKey.zip", mode="wb")
            unzip("Coursera-SwiftKey.zip", exdir = "Coursera-SwiftKey")
        }
        
        if (!file.exists("profanity.txt")) {
            url <- "https://gist.githubusercontent.com/ryanlewis/a37739d710ccdb4b406d/raw/3b70dd644cec678ddc43da88d30034add22897ef/google_twunter_lol"
            download.file(url, "profanity.txt", mode="wt")
        }    
        dataset.recurse("Coursera-SwiftKey/final/",
                        outdir, dataset.create, breakdown)
    }
}
###########################
###########################

#dont load RWeka due to multi-core issues. See link below
#http://stackoverflow.com/questions/17703553/bigrams-instead-of-single-words-in-termdocument-matrix-using-r-and-rweka/20251039
#library(RWeka) 


#profanity obtained from https://gist.github.com/ryanlewis/a37739d710ccdb4b406d


preProcessCorpusSource <- function(corpSrc, rdCtrl=NULL, rm.stop=TRUE) {
    
    if (is.null(rdCtrl)) {
        rdCtrl <- list(reader=readPlain,
                       language="en", #hardcode for now
                       load=TRUE)
    }
    
    corp <- Corpus(corpSrc, readerControl = rdCtrl)
    if (!exists("profanity")) {
        profanity <<- readLines("profanity.txt", warn=FALSE, skipNul=TRUE)
    }
    
    doc.ids <- rownames(summary(corp))
    #print(doc.ids)
    corp <- tm_map(corp, content_transformer(tolower))
    corp <- tm_map(corp, PlainTextDocument)
    corp <- tm_map(corp, content_transformer(removePunctuation))
    if (rm.stop == TRUE) {
        corp <- tm_map(corp, removeWords, c(stopwords("english"), profanity))
    }
    corp <- tm_map(corp, content_transformer(removeNumbers))    
    corp <- tm_map(corp, stripWhitespace)
    corp <- tm_map(corp, stemDocument)
    for (i in 1:length(corp)) {
        corp[[i]]$meta$id <- doc.ids[i]
    }
    #print (summary(corp))
    corp
}

preProcessCorpusDir <- function(dir, pattern) {
    p1 <- proc.time()
    #dat <- readLines(file)
    if (is.null(pattern)) {
        pattern = "*"
    }
    dirSource <- DirSource(dir, pattern=pattern)
    readerControl <- list(reader=readPlain,
                          language="en", #hardcode for now
                          load=TRUE)

    corp <- preProcessCorpusSource(dirSource, readerControl)
}

make_ngram_table <- function (corp, ngram) {
    tokenizer <- function(x) RWeka::NGramTokenizer(x, RWeka::Weka_control(min = ngram, max = ngram))
    tdm <- TermDocumentMatrix(corp, control = list(tokenize = tokenizer))
}

make_ngrams <- function(dir) {
    if (!file.exists(dir)) get_dataset(dir, breakdown=list(train=10, cv=45, test=45))
    if (!exists("en.corp")) en.corp <<- preProcessCorpusDir(paste0(dir,"/en_US/"), "*.train")
    if (!exists("en.1grams")) en.1grams <<- make_ngram_table(en.corp, 1)
    if (!exists("en.2grams")) en.2grams <<- make_ngram_table(en.corp, 2)
    if (!exists("en.3grams")) en.3grams <<- make_ngram_table(en.corp, 3)
    if (!exists("en.4grams")) en.4grams <<- make_ngram_table(en.corp, 4)
    if (!exists("en.5grams")) en.5grams <<- make_ngram_table(en.corp, 5)
    
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
    mar.old <-par("mar")
    par(mar=c(2,15,2, 2))
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
                      names.arg=c(as.character(freq$word)), cex.names=0.7, las=1)
    }
    f <- list(freq=freq, plot = bp);
    par(mar=mar.old)
    return(f)
}

prepareCleanedCorpus <- function(indir, outdir) {
    corp <- preProcessCorpusDir(indir, "*.txt")
    if (!file.exists(outdir)) {
        dir.create(outdir)
    }
    writeCorpus(corp, path = outdir)
    corp
}

doCleanCorpus <- function() {
    corp <- prepareCleanedCorpus("Coursera-SwiftKey/final/en_US/", "./data.cleaned")
}


predictQuiz3 <- function(mainCorp, cleanedDir) {
    
    dd<-data.frame(
        id=1:10,
        text=c("The guy in front of me just bought a pound of bacon, a bouquet, and a case of",
               "You're the reason why I smile everyday. Can you follow me please? It would mean the",
               "Hey sunshine, can you follow me and make me the",
               "Very early observations on the Bills game: Offense still struggling but the",
               "Go on a romantic date at the",
               "Well I'm pretty sure my granny has some old bagpipes in her garage I'll dust them off and be on my",
               "Ohhhhh #PointBreak is on tomorrow. Love that film and haven't seen it in quite some",
               "After the ice bucket challenge Louis will push his long wet hair out of his eyes with his little",
               "Be grateful for the good times and keep the faith during the",
               "If this isn't the cutest thing you've ever seen, then you must be")
        ,stringsAsFactors=F
    )
    dd.choices=matrix(
        c("cheese",    "beer",        "pretzels", "soda",
          "world",     "most",        "best",     "universe",
          "happiest",  "bluest",      "saddest",  "smelliest",
          "players",   "crowd",       "defense",  "referees",
          "mall",      "movies",      "grocery",  "beach",
          "motorcycle","phone",       "way",      "horse",
          "weeks",     "years",       "thing",    "time",
          "fingers",   "toes",        "ears",     "eyes",
          "worse",     "sad",         "bad",      "hard",
          "callous",   "insensitive", "asleep",   "insane"),
        ncol=4, byrow=TRUE)
    
    rdCtrl <- list(reader = readTabular(mapping=list(content="text", id="id")))
    
    dd.choices <- paste(dd.choices, collapse=" ")
    #print(dd.choices)
    #dd.choices <- matrix(strsplit(dd.choices, " ")[[1]], ncol=4, byrow=FALSE)
    dfChoices <- DataframeSource(data.frame(id = 1, text=dd.choices, stringsAsFactors=F))
    dfChoicesCorp <- preProcessCorpusSource(dfChoices, rdCtrl, rm.stop=FALSE)
    #print(dfChoicesCorp[[1]]$content)
    dd.choices <- matrix(strsplit(dfChoicesCorp[[1]]$content, " ")[[1]], ncol=4, byrow=FALSE)
    #print(dd.choices)
    
    dfSource <- DataframeSource(dd)
    rdCtrl <- list(reader = readTabular(mapping=list(content="text", id="id")))
    corp <- preProcessCorpusSource(dfSource, rdCtrl)
    
    df4w <- sapply(1:length(corp), function(x) {
        spl <- strsplit(corp[[x]]$content, " ")[[1]]
        n <- length(spl)
        w0 <- spl[n]
        w1 <- spl[n-1]
        w2 <- spl[n-2]
        w3 <- spl[n-3]
        #print(paste(w0,w1,w2,w3))        
        list(w0 = w0, w1 = w1, w2 = w2, w3 = w3)
    })
    df4w <- t(df4w)
    #print(df4w)
    
    #run the following command with w0
    #grep -oh "w0 [a-z]\+" *.txt | sort | uniq -c | sort

    for (i in 1:nrow(df4w)) {
        
        #cmd <- paste("grep -oh \"", df4w[i,]$w0," [a-z]+\" ", 
        #             cleanedDir, "/*.txt | sort | uniq -c | sort -n",
        #             sep="")
        
        cmd <- paste("get_next_word", df4w[i,]$w0, cleanedDir)
        #print(cmd)                 
        sysout <- system(cmd, intern=TRUE)
        #print(sysout)
        sysout <- gsub("(\\d+) \\w+ (\\w+)", "\\1,\\2", sysout, perl=TRUE, ignore.case=TRUE)
        con <- textConnection(sysout)
        sysout <- read.csv(con, header=FALSE, col.names=c("count", "words"))
        #print(tail(sysout))
        
        choices <- dd.choices[i,]
        print(corp[[i]]$content)
        print(choices)
        print(sysout[sysout$words %in% choices,])
        close(con)
    }
    
    #wordHits <- sapply(1:nrow(df4w), function(x) {
    #    w0 <- df4w[x,1]
    #    words <- c()
    #    for (i in 1:length(mainCorp)) {
    #        pattern <- paste0(w0, " (\\w+) .*")
    #        print(paste0("'", pattern, "'"))
    #        ws <- gsub(pattern, "\\1", mainCorp[[i]]$content, perl=TRUE)
    #        if ((i == 1) && (x == 1)) {
    #            print(ws)
    #            #cat("w0=", w0, ", words=", as.vector(ws))
    #        }
    #        words <- c(words, ws)
    #    }
    #    #print(words)
    #    list(w0 = w0, hits = words)
    #})
    #wordHits <- t(wordHits)
}

