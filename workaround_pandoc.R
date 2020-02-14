# workaround Pandoc : https://github.com/rstudio/rmarkdown/issues/1268
rmarkdown::render(
  input = "README.Rmd",
  output_format = "github_document",
  output_file = "README.md",
  output_dir = "~/",
  intermediates_dir = "D://"
)
