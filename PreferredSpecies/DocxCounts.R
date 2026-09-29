# Render-verification helper (F41 + F87). Not sourced by the report; source by hand
# after a render and compare against the baseline in AGENTS.md §6.
# Counts tblHeader rows, so each Ch. 5 icon header row reads as a table (F87).
# The leaked-markup regex is the F41 one; a naive scan gives false positives.

library(stringr)

DocxCounts <- function(path) {
  tmp <- tempfile()
  unzip(path, files = "word/document.xml", exdir = tmp)
  xml <- paste(readLines(file.path(tmp, "word/document.xml"), warn = FALSE, encoding = "UTF-8"), collapse = "")
  runs <- str_match_all(xml, "<w:t(?: [^>]*[^/>])?>(.*?)</w:t>")[[1]][, 2]
  c(
    tables = str_count(xml, "<w:tblHeader"),
    images = str_count(xml, "<pic:pic"),
    landscape = str_count(xml, 'w:orient="landscape"'),
    leaked = sum(str_detect(runs, "w:tblPr|w:sectPr|w:pgSz|&lt;!--"))
  )
}
