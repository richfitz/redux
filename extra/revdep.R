#!/usr/bin/env Rscript
path <- "revdep"
if (file.exists(path)) {
  unlink(path, recursive=TRUE)
}
dir.create(path)

devtools::install(".")

packages <- c("ropensci/rrlite",
              "richfitz/redux",
              "richfitz/storr",
              "richfitz/RedisHeartbeat",
              "traitecoevo/rrqueue")

## This is dropped for now because there's an issue that I only see on
## travis (can't replicate on OS/X or docker or see in typical usage).
packages <- setdiff(packages, "traitecoevo/rrqueue")

if (Sys.getenv("USER") == "rich") {
  prefix <- "~/Documents/src"
  packages <- basename(packages)
} else {
  prefix <- "https://github.com"

  deps <- c("traitecoevo/callr")
  for (d in deps) {
    devtools::install_github(d)
  }
}

for (p in packages) {
  system2("git", c("clone", "--recursive",
                   file.path(prefix, p), file.path(path, p)))
  devtools::install(file.path(path, p))
}

res <- list()
for (p in packages) {
  res[[p]] <- devtools::test(file.path(path, p))
}

nb <- sum(vapply(res, function(x) sum(as.data.frame(x)$nb), integer(1)))
failed <- sum(vapply(res, function(x) sum(as.data.frame(x)$failed), integer(1)))
if (failed > 0) {
  stop(sprintf("%d / %d tests failed", failed, nb))
} else {
  message(sprintf("All %d tests passed", nb))
}
