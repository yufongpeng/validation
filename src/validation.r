library(data.table)
library(jsonlite)
library(this.path)
library(purrr)

comp <- function(df, levels){
  analyte <- colnames(df)[3]
  df <- data.table(reshape(df, idvar = "id", timevar = "day", direction = "wide"))
  df[[1]] <- levels
  colnames(df) <- c("level", seq(1, length(df) - 1))
  tmp.df <- data.frame(level = unique(levels), analyte = analyte)
  id <- 0
  accuracy.intra.id <- c()
  for (col.id in colnames(df)[-1]){
    id <- id + 1
    tmp.df[[paste("accuracy", "intra", id, sep = ".")]] <- df[, mean(get(col.id)), by = level][[2]]
    accuracy.intra.id <- c(accuracy.intra.id, 2 * id + 1)
    tmp.df[[paste("std", "intra", id, sep = ".")]] <- df[, sd(get(col.id)), by = level][[2]]
  }
  tmp.df[[paste("sigma", "intra", sep = ".")]] <- pmap(tmp.df[, accuracy.intra.id + 1], ~c(...)) %>% map_dbl(~sqrt(mean(.^2)))
  std.intra.mean.id <- 2 * id + 3
  tmp.df[, paste("rsd", "intra", seq(1, id), sep = ".")] <- tmp.df[, std.intra.mean.id] / tmp.df[, accuracy.intra.id]
  tmp.df[[paste("accuracy", "inter", sep = ".")]] <- pmap(tmp.df[, accuracy.intra.id], ~c(...)) %>% map_dbl(~mean(.))
  tmp.df[[paste("std", "inter", sep = ".")]] <- pmap(tmp.df[, accuracy.intra.id], ~c(...)) %>% map_dbl(~sd(.))
  id <- std.intra.mean.id + id + 3
  tmp.df[[paste("sigma", "inter", sep = ".")]] <- map_dbl(tmp.df[, id - 1]^2 - tmp.df[, std.intra.mean.id]^2/id, ~sqrt(max(0, .)))
  tmp.df[[paste("rsd", "inter", sep = ".")]] <- tmp.df[, id] / tmp.df[, id - 2]
  return(tmp.df)
}

validation <- function(df){
  df <- df[!is.na(df[[2]]),]
  fill.level <- is.numeric(df[[1]])
  if (fill.level){
    df[[1]] <- nafill(df[[1]], "locf")
  }else{
    for (i in 1:nrow(df)){
      if (df[i, 1] == ""){
        df[i, 1] <- fill
      }else{
        fill <- df[i, 1]
      }
    }
  }
  n <- 0    # n repeats, assume constant
  for (x in df[[1]]){
    if (x == df[1, 1]){
      n <- n + 1
    }else{
      break
    }
  }
  levs <- length(unique(df[[1]])) * n
  day <- length(df[[1]]) / levs
  levels <- df[[1]][1:levs]
  df[[1]] <- rep(levels, day)
  if (fill.level){
    for (i in seq(2, length(df))){
      df[[i]] <- df[[i]] / df[[1]]
    }
  }
  df[["day"]] <- rep(1:day, each = levs)
  df[["id"]] <- rep(seq(1, levs), day)
  basein <- c(length(df), length(df) - 1)
  return(map(seq(2, length(df) - 2), ~comp(df[, c(basein, .)], levels)))
}

data.split <- function(data.file){
  df <- read.csv(data.file)
  id.start <- grep("^level", colnames(df))
  id.start <- c(id.start, length(df) + 1)
  return(map(seq(1, length(id.start) - 1), ~df[, id.start[.]:(id.start[. + 1] - 1)]))
}

main <- function(){
  data.files <- choose.files()
  #kw <- read_json(paste(dirname(this.path()), "/config.json", sep = ""))
  dfs <- map(data.files, ~data.split(.) %>% map(validation) %>% reduce(~c(...)))
  combine.files <- askYesNo("Do you want to combine all analytes into one csv file?")
  ns <- map(dfs, ~map(., ~length(.)))
  if (combine.files && reduce(ns, ~c(...)) %>% unique %>% length > 1){
      combine.files <- FALSE
      split.files <- askYesNo("Fail to combine all analytes. Do you want to split all analytes into different csv files?")
  }else{
    split.files <- askYesNo("Do you want to split all analytes into different csv files?")
  }
  if (combine.files){
    filename <- data.files %>% map_chr(~gsub("\\", "_", ., fixed = TRUE) %>% gsub(".*_", "", .) %>% gsub(".csv$", "", .)) %>% c(., "validation.csv") 
    rootname <- gsub(paste(filename[1], "csv", sep = "."), "", data.files[1])
    filename <- paste(rootname, filename %>% reduce(~paste(..., sep = "_")), sep = "")
    print(filename)
    write.csv(dfs %>% map(~reduce(., rbind)) %>% reduce(rbind), file = filename, row.names = FALSE) 
  }else{
    if (split.files){
      dfs %>% map2(data.files, ~map2(.x, .y, ~write.csv(.x, print(gsub(".csv$", paste("", .x[1, 2], "validation.csv", sep = "_"), .y)), row.names = FALSE)))
    }else{
      split <- map_lgl(ns, ~unique(.) %>% length > 1)
      dfs[split] %>% map2(data.files[split], ~map2(.x, .y, ~write.csv(.x, print(gsub(".csv$", paste("", .x[1, 2], "validation.csv", sep = "_"), .y)), row.names = FALSE)))
      dfs[!split] %>% map(~reduce(., rbind)) %>% map2(data.files[!split], ~write.csv(.x, print(gsub(".csv$", "_validation.csv", .y)), row.names = FALSE))
    }
  }
  return()
}

main()

