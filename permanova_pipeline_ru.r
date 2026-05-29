library(tidyverse)
library(RVAideMemoire)
library(effectsize)
library(openxlsx)
library(vegan)

# =========================================================
# ШАГ 1 — ЗАГРУЗКА ФАЙЛА
# =========================================================

cat("Введите путь к CSV файлу:\n")
file_path <- readline()
file_path <- gsub('"', '', file_path)  # убираем кавычки Windows

if (!file.exists(file_path)) stop("Файл не найден. Проверьте путь.")

cat("\nКакой разделитель в файле?\n1 — запятая (,)\n2 — точка с запятой (;)\n")
sep_choice <- readline("Введите 1 или 2: ")
sep_char <- ifelse(sep_choice == "2", ";", ",")

df_raw <- read.csv(file_path, sep = sep_char, stringsAsFactors = FALSE)

cat("\nФайл загружен. Первые строки:\n")
print(head(df_raw))
cat("\nСтолбцы:\n")
print(names(df_raw))

# =========================================================
# ШАГ 2 — ФАКТОРЫ
# =========================================================

cat("\nСколько факторов? (2 или 3):\n")
n_factors <- as.integer(readline())
if (!n_factors %in% c(2, 3)) stop("Введите 2 или 3.")

factors <- c()
for (i in 1:n_factors) {
  cat(sprintf("Введите название фактора %d:\n", i))
  f <- trimws(readline())
  if (!f %in% names(df_raw)) stop(sprintf("Столбец '%s' не найден в таблице.", f))
  factors <- c(factors, f)
}

df <- df_raw
for (f in factors) {
  df[[f]] <- factor(df[[f]])
}

cat("\nФакторы приняты:", paste(factors, collapse = ", "), "\n")

# =========================================================
# ШАГ 3 — КОЛИЧЕСТВО ПЕРЕМЕННЫХ
# =========================================================

cat("\nСколько переменных анализировать?\n")
n_vars <- as.integer(readline())
if (is.na(n_vars) || n_vars < 1) stop("Введите целое число больше 0.")

# =========================================================
# ШАГ 4 — НАЗВАНИЯ ПЕРЕМЕННЫХ
# =========================================================

columns <- c()
for (i in 1:n_vars) {
  cat(sprintf("Введите название переменной %d:\n", i))
  v <- trimws(readline())
  if (!v %in% names(df)) stop(sprintf("Столбец '%s' не найден в таблице.", v))
  if (v %in% factors) stop(sprintf("'%s' уже используется как фактор.", v))
  columns <- c(columns, v)
}

# =========================================================
# ШАГ 5 — ПОДТВЕРЖДЕНИЕ СПИСКА
# =========================================================

cat("\nПеременные для анализа:\n")
print(columns)
cat("\nПродолжить? (y/n):\n")
confirm <- tolower(trimws(readline()))
if (confirm != "y") stop("Анализ отменён. Запустите скрипт заново.")

# =========================================================
# ШАГ 6 — ПУТЬ СОХРАНЕНИЯ И ПОПРАВКА
# =========================================================

cat("\nВведите путь для сохранения результата (Enter — сохранить в текущую папку):\n")
out_path <- trimws(gsub('"', '', readline()))
if (out_path == "") {
  out_path <- file.path(getwd(), "PERMANOVA_results.xlsx")
} else {
  if (dir.exists(out_path)) {
    out_path <- file.path(out_path, "PERMANOVA_results.xlsx")
  }
}
cat("Результат будет сохранён в:", out_path, "\n")

cat("\nВыберите поправку на множественные сравнения для пост-хока:\n")
cat("1 — holm\n2 — bonferroni\n3 — BH\n4 — BY\n5 — none\n")
p_choice <- trimws(readline("Введите номер: "))
p_method <- switch(p_choice,
  "1" = "holm",
  "2" = "bonferroni",
  "3" = "BH",
  "4" = "BY",
  "5" = "none",
  "holm"
)
cat("Выбрана поправка:", p_method, "\n")

# =========================================================
# HELPERS
# =========================================================

get_stars <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    TRUE      ~ ""
  )
}

safe_d <- function(x, g) {
  tryCatch(cohens_d(x ~ g, pooled_sd = TRUE),
           error = function(e) NULL)
}

# =========================================================
# ШАГ 7 — АНАЛИЗ
# =========================================================

primary_results <- list()
all_results     <- list()

# Формула для adonis2
formula_str <- paste("d ~", paste(factors, collapse = " * "))

for (col in columns) {
  
  cat("Processing:", col, "\n")
  
  tmp <- df %>%
    select(all_of(c(factors, col))) %>%
    drop_na()
  
  names(tmp)[ncol(tmp)] <- "Myelin"
  
  if (nrow(tmp) < 12) next
  
  # ---------------------------------------------------
  # PRIMARY: adonis2
  # ---------------------------------------------------
  
  prim <- tryCatch({
    
    d <- dist(tmp$Myelin, method = "euclidean")
    
    res <- adonis2(
      as.formula(formula_str),
      data         = tmp,
      permutations = 9999,
      method       = "euclidean",
      by           = "terms"
    )
    
    tbl <- as.data.frame(res)
    
    data.frame(
      Structure = col,
      Term      = rownames(tbl),
      Df        = tbl$Df,
      SumOfSqs  = round(tbl$SumOfSqs, 4),
      R2        = round(tbl$R2, 4),
      F         = round(tbl$F, 4),
      p_value   = tbl$`Pr(>F)`,
      stars     = get_stars(tbl$`Pr(>F)`),
      stringsAsFactors = FALSE
    )
    
  }, error = function(e) {
    cat("  [ERROR] adonis2:", e$message, "\n")
    NULL
  })
  
  primary_results[[col]] <- prim
  
  # ---------------------------------------------------
  # POST-HOC: внутри каждого фактора
  # ---------------------------------------------------
  
  factor1 <- factors[1]
  factor2 <- factors[2]
  
  posthoc_res <- list()
  counter <- 1
  
  for (lvl in levels(tmp[[factor2]])) {
    
    sub <- tmp %>% filter(.data[[factor2]] == lvl)
    
    if (length(unique(sub[[factor1]])) < 2) next
    
    test <- tryCatch(
      pairwise.perm.t.test(sub$Myelin, sub[[factor1]],
                           nperm    = 10000,
                           p.method = p_method),
      error = function(e) NULL
    )
    
    if (!is.null(test)) {
      
      pmat <- as.data.frame(as.table(test$p.value))
      names(pmat) <- c("g1","g2","p_value")
      
      for (i in 1:nrow(pmat)) {
        
        r <- pmat[i, ]
        
        d <- safe_d(
          sub$Myelin[sub[[factor1]] %in% c(r$g1, r$g2)],
          sub[[factor1]][sub[[factor1]] %in% c(r$g1, r$g2)]
        )
        
        posthoc_res[[counter]] <- data.frame(
          Structure  = col,
          Comparison = paste(r$g1, "vs", r$g2,
                             sprintf("(%s: %s)", factor2, lvl)),
          Cohen_d    = ifelse(is.null(d), NA, d$Cohens_d),
          p_value    = r$p_value,
          stars      = get_stars(r$p_value)
        )
        counter <- counter + 1
      }
    }
  }
  
  all_results[[col]] <- bind_rows(posthoc_res)
}

# =========================================================
# ФИНАЛЬНЫЕ ТАБЛИЦЫ
# =========================================================

# Primary
primary_all <- bind_rows(primary_results)

primary_all <- primary_all %>%
  group_by(Term) %>%
  mutate(FDR       = p.adjust(p_value, method = "BH"),
         stars_FDR = get_stars(FDR)) %>%
  ungroup()

primary_sig <- primary_all %>%
  filter(!is.na(FDR), FDR < 0.05)

# Post-hoc
posthoc_all <- bind_rows(all_results)

if (nrow(posthoc_all) > 0) {
  posthoc_all$FDR       <- p.adjust(posthoc_all$p_value, method = "BH")
  posthoc_all$stars_FDR <- get_stars(posthoc_all$FDR)
  
  posthoc_sig <- posthoc_all %>% filter(!is.na(FDR), FDR < 0.05)
} else {
  posthoc_sig <- posthoc_all
}

# =========================================================
# ЭКСПОРТ
# =========================================================

wb <- createWorkbook()

addWorksheet(wb, "Primary_all")
writeData(wb, "Primary_all", primary_all)

addWorksheet(wb, "Primary_significant")
writeData(wb, "Primary_significant", primary_sig)

addWorksheet(wb, "PostHoc_all")
writeData(wb, "PostHoc_all", posthoc_all)

addWorksheet(wb, "PostHoc_significant")
writeData(wb, "PostHoc_significant", posthoc_sig)

saveWorkbook(wb, out_path, overwrite = TRUE)

cat("\nГотово!\n")
cat("Сохранено в:", out_path, "\n")
cat("Primary rows      :", nrow(primary_all), "\n")
cat("Primary sig. rows :", nrow(primary_sig), "\n")
cat("PostHoc rows      :", nrow(posthoc_all), "\n")
cat("PostHoc sig. rows :", nrow(posthoc_sig), "\n")