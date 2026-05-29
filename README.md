# MRI Brain Segmentation Pipeline

**Author:** Maria Shadrina  
**Contact:** shadrina@mail.tsu.ru  
**Affiliation:** Tomsk State University  

---

## Overview

An automated Python pipeline for processing quantitative MRI brain segmentation data across multiple subjects. The pipeline remaps atlas labels, separates grey and white matter, refines cortical boundaries, removes demyelination lesions, and extracts per-structure metrics (mean MRI intensity and volume) for a cohort of subjects.

The pipeline is fully interactive — no code editing required. Both scripts are run from the console with step-by-step prompts.

---

## Features

- Automated batch processing of multiple subject folders
- Flexible file detection via glob patterns (handles naming variations)
- Atlas label remapping and GM/WM separation
- Cortical boundary refinement via tissue segmentation mask
- Optional demyelination lesion removal
- Per-structure mean MRI intensity and volume (mL) extraction
- Results exported to a structured `.xlsx` file (2 sheets)
- Test mode: run and inspect results for a single subject before full batch

---

## Requirements

```bash
pip install nibabel numpy pandas openpyxl
```

Tested on Python 3.8+

---

## Input Data Format

Each subject must have its own folder inside the input directory. The pipeline expects the following files per subject:

| File | Description | Required |
|------|-------------|----------|
| `JHU_MNI_SS_WMPM_Type-III_MPF*.nii(.gz)` | Brain atlas segmentation file with 44 labelled structures | ✅ Yes |
| `MPFuncor_coef_trim_seg.nii(.gz)` | Grey/white matter tissue segmentation mask | ✅ Yes |
| `MPFuncor_coef_transform.nii(.gz)` | Source quantitative MRI map (e.g. MPF) | ✅ Yes |
| `lesions.nii(.gz)` | Binary demyelination lesion mask | ⬜ Optional |

Example input structure:

```
input_data/
├── subject_01/
│   ├── JHU_MNI_SS_WMPM_Type-III_MPF_Ranz_Sha.nii.gz
│   ├── MPFuncor_coef_trim_seg.nii.gz
│   ├── MPFuncor_coef_transform.nii
│   └── lesions.nii.gz
├── subject_02/
│   └── ...
```

> The pipeline uses flexible filename matching, so minor naming variations are handled automatically.

---

## How to Run

1. Clone the repository or download both scripts
2. Run the main script from the terminal:

```bash
python process_segmentation.py
```

3. Follow the console prompts:

```
Enter path to data folder:        <folder containing subject subfolders>
Enter path to processing script:  <path to segmentation_script.py>
Enter path to save results:       <output folder, or Enter to save next to data>
```

4. Select a mode:

```
SELECT MODE:
1 - Test on a single folder
2 - Process all folders
```

> **Windows tip:** You can paste paths directly from File Explorer using *Copy as path* — surrounding quotes are stripped automatically.

---

## Pipeline Steps

For each subject, `segmentation_script.py` performs the following steps:

| Step | Description |
|------|-------------|
| 1 · Remap structure labels | Reorders atlas labels to align subcortical and cortical structure numbering |
| 2 · Separate GM / WM | Splits the atlas into grey matter (labels 1–19) and white matter (labels 20+) |
| 3 · Process tissue mask | Recodes the tissue segmentation mask to binary GM/WM classes |
| 4 · Refine cortical boundaries | Multiplies WM atlas by tissue mask to refine cortical region definitions |
| 5 · Combine segmentation regions | Merges GM structures and refined cortex into a single segmentation |
| 6 · Exclude demyelination lesions | Zeros out lesion voxels in the final segmentation (skipped if no lesion file found) |

After all subjects are processed, `process_segmentation.py` extracts metrics and saves results to Excel.

---

## Output

### Per-subject intermediate files

Each subject folder will contain:

| File | Description |
|------|-------------|
| `remapped.nii.gz` | Atlas with remapped label order |
| `remapped_GM.nii.gz` | Grey matter structures only |
| `remapped_WM.nii.gz` | White matter structures only |
| `processed_mask.nii` | Recoded tissue mask |
| `segmented_cortex.nii` | WM atlas refined by tissue mask |
| `combined_result.nii.gz` | Final segmentation used for metric extraction |

### Results spreadsheet

A single `results_YYYYMMDD_HHMMSS.xlsx` file is saved to the output folder:

| Sheet | Contents |
|-------|----------|
| `Mean_Intensity` | Mean MRI intensity per structure per subject |
| `Volume_mL` | Volume (mL) per structure per subject |

In both sheets: **rows = subjects**, **columns = brain structures**.  
Service labels (Label 30, Label 60) are excluded from output.

### Column descriptions

| Column | Description |
|--------|-------------|
| Row index (folder) | Subject folder name |
| Structure columns | One column per brain structure (42 total) |
| Values | Mean MRI intensity or volume in mL for each subject–structure pair |

### Brain structures (42 total)

| Label | Structure | Label | Structure |
|-------|-----------|-------|-----------|
| 2 | Caudate_L | 3 | Caudate_R |
| 4 | Putamen_L | 5 | Putamen_R |
| 6 | Thalamus_L | 7 | Thalamus_R |
| 8 | Globus_pallidus_L | 9 | Globus_pallidus_R |
| 10 | Hippocamp_L | 11 | Hippocamp_R |
| 12 | Amigdala_L | 13 | Amigdala_R |
| 14 | Corpus_callosum | 15 | Fornix |
| 16 | Brainstem | 17 | Pons |
| 18 | Substantia_nigra_L | 19 | Substantia_nigra_R |
| 20 | Occipital_cortex_L_GM | 21 | Occipital_cortex_R_GM |
| 22 | Parietal_cortex_L_GM | 23 | Parietal_cortex_R_GM |
| 24 | Insular_cortex_L_GM | 25 | Insular_cortex_R_GM |
| 26 | Temporal_cortex_L_GM | 27 | Temporal_cortex_R_GM |
| 28 | Frontal_cortex_L_GM | 29 | Frontal_cortex_R_GM |
| 32 | Cerebellum_L_GM | 33 | Cerebellum_R_GM |
| 40 | Occipital_cortex_L_WM | 42 | Occipital_cortex_R_WM |
| 44 | Parietal_cortex_L_WM | 46 | Parietal_cortex_R_WM |
| 48 | Insular_cortex_L_WM | 50 | Insular_cortex_R_WM |
| 52 | Temporal_cortex_L_WM | 54 | Temporal_cortex_R_WM |
| 56 | Frontal_cortex_L_WM | 58 | Frontal_cortex_R_GM |
| 64 | Cerebellum_L_WM | 66 | Cerebellum_R_WM |

---

## Example Data & Output

- `input_example/` — anonymized example subject folders with input NIfTI files
- `output_example/` — example output including intermediate `.nii.gz` files and `results.xlsx`

---

## License

MIT License. Free to use and modify with attribution.

---

## Citation

If you use this pipeline in your research, please cite:

```
Shadrina, M. (2026). MRI Brain Segmentation Pipeline.
GitHub: https://github.com/M-M-Shadrina/mri-segmentation-pipeline
```
