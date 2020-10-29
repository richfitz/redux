if (!file.exists("../windows/hiredis-1.0.0/include/hiredis/hiredis.h")) {
  if (getRversion() < "3.3.0") setInternet2()
  download.file("https://github.com/rwinlib/hiredis/archive/v1.0.0.zip", "lib.zip", quiet = TRUE)
  dir.create("../windows", showWarnings = FALSE)
  unzip("lib.zip", exdir = "../windows")
  unlink("lib.zip")
}
