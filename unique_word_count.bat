@cat %1 | tr 'A-Z' 'a-z'| tr -sc 'A-za-z' '\n'| uniq | wc -l