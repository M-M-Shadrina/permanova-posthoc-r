# PERMANOVA + Post-hoc Pipeline

**Author:** Maria Shadrina  
**Contact:** shadrina@mail.tsu.ru  
**Affiliation:** Tomsk State University  

> 🇷🇺 [Читать на русском](README_ru.md)

---

## Overview

An interactive R script for running **PERMANOVA** (`adonis2`, vegan)  
followed by **pairwise permutation t-tests** (post-hoc) across multiple  
dependent variables simultaneously.  
Results are exported to a structured **Excel workbook** with four sheets.

---

## Repository contents

| File | Description |
|------|-------------|
| `permanova_pipeline_en.R` | Main script (English prompts) |
| `permanova_pipeline_ru.R` | Main script (Russian prompts) |
| `table_example.csv` | Example input file |
| `PERMANOVA_results.xlsx` | Example output produced by the script |
| `README.md` | This file (English) |
| `README_ru.md` | Documentation in Russian |

---

## Requirements

| Package | Purpose |
|---------|---------|
| `tidyverse` | Data manipulation |
| `vegan` | PERMANOVA (`adonis2`) |
| `RVAideMemoire` | Pairwise permutation t-test |
| `effectsize` | Cohen's *d* |
| `openxlsx` | Excel export |

Install all at once:

```r
install.packages(c("tidyverse", "vegan", "RVAideMemoire",
                   "effectsize", "openxlsx"))
Input data format
A CSV file with:

Factor columns — categorical grouping variables (e.g. Group, Sex)
Variable columns — numeric dependent variables (e.g. Weight, Length)
Supported delimiters: , (comma) or ; (semicolon).

Example input table
Example input table

The table contains factor columns (Group, Age_Group, Gender)

and multiple numeric variables (brain structure volumes).

How to run
Open R or RStudio.
Source the script:
r

source("permanova_pipeline_en.R")
Follow the interactive prompts:

Step 1 — path to CSV file
Step 2 — delimiter (1 = comma, 2 = semicolon)
Step 3 — number of factors (2 or 3) and their column names
Step 4 — number of dependent variables and their column names
Step 5 — confirm the variable list
Step 6 — output path (Enter = current directory)
Step 7 — p-value correction method for post-hoc tests
Statistical workflow

For each dependent variable
│
├── PERMANOVA (adonis2, euclidean distance, 9 999 permutations)
│     Model: variable ~ factor1 * factor2 [* factor3]
│     Output: Df, SumOfSqs, R², F, p-value, significance stars
│     FDR correction applied across all variables (BH method)
│
└── Post-hoc: pairwise permutation t-test (RVAideMemoire)
      Performed within each level of factor2
      Effect size: Cohen's d (pooled SD)
      User-selected p correction: Holm / Bonferroni / BH / BY / none
      FDR correction applied across all comparisons (BH method)
Output
The script saves PERMANOVA_results.xlsx with four sheets:

Sheet	Contents
Primary_all	Full PERMANOVA table for all variables
Primary_significant	Rows with FDR < 0.05
PostHoc_all	All pairwise comparisons
PostHoc_significant	Pairwise comparisons with FDR < 0.05
Significance codes: * p < 0.05 · ** p < 0.01 · *** p < 0.001

Example output — Primary results (PERMANOVA)
Primary results

Sheet Primary_all: PERMANOVA results for each structure and term,

with R², F-statistic, p-value and FDR-corrected significance.

Example output — Post-hoc results
Post-hoc results

Sheet PostHoc_all: pairwise comparisons within each level of factor 2,

with Cohen's d effect size, p-value and FDR correction.

Notes
Variables with fewer than 12 observations are skipped automatically.
The script handles errors gracefully: if adonis2 or the post-hoc test
fails for a variable, that variable is skipped and processing continues.
Windows users: you may paste a path with quotes — they are stripped
automatically.
Citation
If you use this script in your research, please cite it as:

Shadrina, M. (2025). PERMANOVA + Post-hoc Pipeline [R script].
License
MIT License. Free to use and modify with attribution.
