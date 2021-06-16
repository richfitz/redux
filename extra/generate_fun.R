indent <- function(x, n = 2) {
  indent <- paste0(rep_len(" ", n), collapse = "")
  paste0(indent, x)
}

reindent <- function(x, n) {
  vcapply(strsplit(x, "\n", fixed = TRUE),
          function(x) paste(indent(x, n), collapse = "\n"))
}

## duplicated from package
vlapply <- function(X, FUN, ...) {
  vapply(X, FUN, logical(1), ...)
}
viapply <- function(X, FUN, ...) {
  vapply(X, FUN, integer(1), ...)
}
vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}

dquote <- function(x) {
  i <- x == '""'
  x[i] <- ""
  sprintf('"%s"', x)
}

## TODO: now that this approximately works, it'd be nice to refactor
## it to make it less awful.

## There's not actually enough information here to work out what is
## required with these commands.  For example in SET, the official
## docs say:
##
##     SET key value [EX seconds] [PX milliseconds] [NX|XX]
##
## but what they actually mean is EX *or* PX
##
## It's actuallly possible that only a single "command" is allowed;
## that'd be easy enough to enforce, but would be frustrating if
## incorrect.  Redis will throw a syntax error if incorrect output is
## given so it's no great deal.

is_field <- function(name, args) {
  if (is.null(args[[name]])) {
    rep(FALSE, nrow(args))
  } else {
    !is.na(args[[name]])
  }
}

hiredis_cmd <- function(x, standalone = FALSE) {
  name <- x$name
  args <- as.data.frame(x$arguments)
  if (name == "COMMAND GETKEYS") {
    args <- data.frame(name = "cmd", variadic = TRUE,
                       stringsAsFactors = FALSE)
  }

  ## This is literally the variadic set
  if (any(args$variadic)) {
    args$multiple[args$variadic] <- TRUE
  }

  is_multiple <- is_field("multiple", args)

  is_command <- is_field("command", args)
  is_grouped <- lengths(args$name) > 1L

  if (any(is_command)) {
    if (is.null(args$name)) {
      args$name <- args$command
    }
    
    j <- is_command & !(is_grouped & is_multiple)
    args$name_orig <- args$name
    args$command_length <- viapply(args$name, length)
    args$name[j] <- args$command[j]
    is_grouped <- viapply(args$name, length) > 1L
  }
  
  if (any(duplicated(args$name))) {
    stop("Duplicated names")
  }
  
  if (any(args$variadic)) {
    args$command_length[args$variadic] <- 2
  }

  ## need to be same length, share optional status.
  if (any(is_grouped)) {
    if (sum(is_grouped) > 1L) {
      stop("multiple grouped arguments")
    }
    len <- length(args$name[[which(is_grouped)]])
    args1 <- args[!is_grouped, , drop = FALSE]

    ## Lots of assumptions here:
    args2 <- args[rep(which(is_grouped), len), ]
    args2$name <- args$name[[which(is_grouped)]]
    args2$type <- args$type[[which(is_grouped)]]

    args3 <- rbind(args1, args2)
    ## Reorder:
    args3 <- args3[match(unlist(args$name), args3$name), ]
    rownames(args3) <- NULL
    group_from <- args$name[[which(is_grouped)]][[1L]]
    group_to   <- args$name[[which(is_grouped)]][-1L]
    args3$grouped <- ""
    args3$grouped[match(group_to, args3$name)] <- group_from

    args3$name <- unlist(args3$name)

    args <- args3

    ## NOTE: Need to redo this here because the number of rows has changed.
    is_multiple <- is_field("multiple", args)
    is_command <- is_field("command", args)
  }

  ## At this point we should have no duplicates
  if (any(duplicated(args$name))) {
    stop("duplicate names")
  }
  ## The colon here is for CLIENT KILL
  ## The space here is for count or RESET
  args$name <- gsub("[-: ]", "_", args$name)
  if (any(grepl("[^A-Za-z0-9._]", args$name))) {
    stop("invalid names: ", paste(args$name, collapse = ", "))
  }

  is_optional <- is_field("optional", args)
  r_fn_args <- args$name
  r_fn_args[is_optional] <- paste0(r_fn_args[is_optional], " = NULL")
  if (!identical(is_optional, sort(is_optional))) {
    r_fn_args <- r_fn_args[order(is_optional)]
  }
  r_fn_args <- paste(c(character(0), r_fn_args), collapse = ", ")

  ## Generate the check string
  ## TODO: Consider dealing with integer types here?
  check <- sprintf("assert_scalar%s2(%s)",
                   ifelse(is_optional, "_or_null", ""),
                   args$name)
  ## Then, for things that take multiple arguments:
  if (any(is_command)) {
    j <- is_command & args$command_length > 1L
    check[j] <- sprintf("assert_length%s(%s, %dL)",
                        ifelse(is_optional[j], "_or_null", ""),
                        args$name[j], args$command_length[j])
  }

  if (any(args$variadic)) {
    j <- which(args$variadic)
    check[j] <- sprintf("assert_length2(%s, length(key))", args$name[j])
  }

  is_enum <- !vlapply(args$enum, is.null)
  if (any(is_enum)) {
    tmp <- vcapply(args$enum[is_enum],
                   function(x) paste(dquote(x), collapse = ", "))
    check[is_enum] <- sprintf("assert_match_value%s(%s, c(%s))",
                              ifelse(is_optional[is_enum], "_or_null", ""),
                              args$name[is_enum], tmp)
  }

  ## NOTE: This assumes that multipleness overrides everything else
  ## (no multiple enums, no multiple commands)
  check <- check[!is_multiple]

  is_grouped <- args$grouped != ""
  ## Here we can't use c() to pull args together but have to
  ## interleave for the grouped ones.  This bit of hackery depends
  ## crucially on the single pair rule.
  if (any(is_grouped & is_multiple)) {
    group <- sprintf("%s <- cmd_interleave(%s, %s)",
                    group_from, group_from, paste(group_to, collapse = ", "))
    vars <- setdiff(args$name, group_to)
  } else {
    group <- NULL
    vars <- args$name
  }

  if (any(is_command)) {
    vars[is_command] <- sprintf("cmd_command(%s, %s, %s)",
                                dquote(vars[is_command]),
                                vars[is_command],
                                args$command_length[is_command] > 1L)
  }

  name_split <- dquote(strsplit(name, " ", fixed = TRUE)[[1]])
  if (name == "COMMAND GETKEYS") {
    args <- sprintf("c(list(%s), %s)", paste(name_split, collapse = ", "), vars)
  } else {
    args <- sprintf("list(%s)", paste(c(name_split, vars), collapse = ", "))
  }
  run <- sprintf("command(%s)", args)

  if (name %in% c("PSUBSCRIBE", "SUBSCRIBE")) {
    ## Don't allow use of PSUBSCRIBE/SUBSCRIBE as it will lock the
    ## session and never do anything useful:
    check <- group <- NULL
    run <- sprintf(
      'stop("Do not use %s(); see subscribe() instead (lower-case)")', name)
  }
  if (name %in% c("CLIENT REPLY", "PSYNC")) {
    check <- group <- NULL
    run <- sprintf('stop("Do not use %s; not supported with this client")',
                   name)
  }
  if (name %in% paste("CLIENT", c("CACHING", "GETREDIR", "TRACKING"))) {
    ## Don't allow use of any client-side caching related functions as
    ## they do nothing useful.
    check <- group <- NULL
    run <- sprintf('stop("Do not use %s; not supported with this client")',
                   name)
  }
  if (name == "HELLO") {
    ## TODO: we *could* support this
    ## https://github.com/redis/hiredis/issues/648
    ##
    ## though there would be other changes required for the package in
    ## terms of the types of responses that we get back:
    ## * check hiredis library version before using
    ## * high-level connection interface should support this
    check <- group <- NULL
    run <- 'stop("Do not use HELLO; RESP3 not supported with this client")'
  }
  if (name == "LOLWUT") {
    run <- c(sprintf("res <- %s", run),
             "message(trimws(res))",
             "invisible(res)")
  }

  fn_body <- paste(indent(c(check, group, run)), collapse = "\n")
  fmt <- "%s = function(%s) {\n%s\n}"
  sprintf(fmt, x$name_r, r_fn_args, fn_body)
}

read_commands <- function() {
  cmds <- jsonlite::fromJSON("redis-doc/commands.json")
  ## Filter commands for releasedness:
  ok <- !vlapply(cmds, function(x) is.null(x$since))
  cmds <- cmds[ok]
  for (i in seq_along(cmds)) {
    cmds[[i]]$name <- names(cmds)[[i]]
    cmds[[i]]$name_r <- clean_name(cmds[[i]]$name)
  }

  ## Now, go through and get the extra doc:
  ## for (i in names(cmds)) {
  ##   p <- sprintf("redis-doc/commands/%s.md", tolower(i))
  ##   if (file.exists(p)) {
  ##     cmds[[i]]$description <- paste(readLines(p), collapse = "\n")
  ##   }
  ## }
  cmds
}

generate <- function(cmds) {
  template <- 'redis_commands <- function(command) {\n  list(\n%s)\n}'
  dat <- vcapply(cmds, hiredis_cmd, NULL, USE.NAMES = FALSE)
  str <- paste(reindent(dat, 4), collapse = ",\n")
  sprintf(template, str)
}

clean_name <- function(x) {
  toupper(gsub("[ -]", "_", x))
}

generate_since <- function(cmds) {
  vv <- vcapply(cmds, function(x) x$since)
  names(vv) <- vcapply(cmds, "[[", "name_r")
  vv <- vv[order(names(vv))]
  sprintf("cmd_since <- numeric_version(c(\n%s))",
          paste(sprintf('  %s = "%s"', names(vv), vv), collapse = ",\n"))
}
