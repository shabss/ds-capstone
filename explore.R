library(tm)
library(filehash)
library(wordnet)

setDict("C:/WordNet/2.1/dict")

language <-"en_US"
corp.path = "./Coursera-SwiftKey/final/"

if (!exists("corp")) {
    corp <- Corpus(DirSource(paste(corp.path, language, "/", sep = "")),
                   readerControl = list(reader=readPlain, 
                                        language=language, 
                                        load=TRUE)
                    #, dbControl = list(useDb = TRUE, dbName = "./nlpdb.db", type="DB1"
                   )

    corp.lower <- tm_map(corp, FUN = tolower)
}

mystopwords <- c("and", "for", "in", "is", 
                 "it", "not", "the", "to")


#using wordnet
synonyms("company", "NOUN")

#POS tagging
library(NLP)
library(openNLP)

tagPOS <-  function(x, ...) {
    s <- as.String(x)
    word_token_annotator <- Maxent_Word_Token_Annotator()
    a2 <- Annotation(1L, "sentence", 1L, nchar(s))
    a2 <- annotate(s, word_token_annotator, a2)
    a3 <- annotate(s, Maxent_POS_Tag_Annotator(), a2)
    a3w <- a3[a3$type == "word"]
    POStags <- unlist(lapply(a3w$features, `[[`, "POS"))
    POStagged <- paste(sprintf("%s/%s", s[a3w], POStags), collapse = " ")
    list(POStagged = POStagged, POStags = POStags)
}

print(tagPOS("this is a word"))


#count frequencies

corpTDM <- TermDocumentMatrix(corp, control=list(stopwords = TRUE))
