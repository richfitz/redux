#!/usr/bin/env Rscript
library(methods)
path_R <- "../R"
source("generate_fun.R")

if (!file.exists("redis-doc")) {
  system2("git", c("clone", "https://github.com/antirez/redis-doc"))
}

cmds <- read_commands()
dat <- generate(cmds)
writeLines(c(dat, generate_since(cmds)),
           file.path(path_R, "redis_api_generated.R"))
