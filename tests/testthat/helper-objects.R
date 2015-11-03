mixed_fake_data <- function(nr) {
  str <- sample(rownames(mtcars), nr, replace=TRUE)
  data.frame(x_logical=(runif(nr) < .3),
             x_numeric=rnorm(nr),
             x_integer=as.integer(rpois(nr, 2)),
             x_character=str,
             x_factor=factor(str),
             stringsAsFactors=FALSE)
}
