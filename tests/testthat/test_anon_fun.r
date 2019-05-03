######### Testing anonymize function ############

context("test_anonymize_function")


test_that("Anonymize function is working", {

  df_exmple <- data.frame("name" = c("Brianna","Gina","Lydia","Stephanie","Yones"),
                          "Salary" = c(5456, 5698, 5647, 5842, 5010))

  expect_error(anonymize(df = df_exmple, info = NULL)) # "df should be a data fram"etra
  expect_error(anonymize(df = df_exmple, calss = NULL, cols_to_anon = "name")) #"to_anon should be a character vector"
  expect_error(anonymize(df = df_exmple, regexp = NULL, algo = "crc32")) # algo is not a string

  set.seed(30000)
  res <- anonymize(df = df_exmple)
  expect_equal(names(res), c("name", "Salary", "id")) # has correct columns on output
  expect_match(res$id, "[a-z0-9]{8}") # sequence of 8 letters and numbers

})
