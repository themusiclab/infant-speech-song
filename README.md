# Acoustic regularities in infant-directed speech and song across cultures

This is the repository for Hilton & Moser et al. (2022) "Acoustic regularities in infant-directed speech and song across cultures". The manuscript is publicly available at https://www.biorxiv.org/content/10.1101/2020.04.09.032995v5.

You can find the following here:
- an R Markdown file that generates the manuscript
- data, analysis, and visualization code to produce the results reported in the manuscript
- supplementary data and materials
- code for the naïve listener experiment

Further data and information are available elsewhere: 
- the complete audio corpus is available at <https://doi.org/10.5281/zenodo.5525161>
- the preregistration for the auditory analyses is at https://doi.org/10.17605/osf.io/5r72u
- you can participate in the naïve listener experiment at <https://themusiclab.org/quizzes/ids>.

**For assistance, please contact the corresponding authors: Courtney Hilton (courtney.hilton@auckland.ac.nz), Cody Moser (cmoser2@ucmerced.edu), and Samuel Mehr (mehr@hey.com).**

## Anatomy of the repo

To render the paper, run the code in `/writing/manuscript.Rmd`.

> **Warning**  
> The manuscript file combines output from several `.Rmd` files devoted to analysis, visualization, and the like. The `full_run` flag in `manuscript.Rmd` determines whether analyses and figures should be generated from scratch (which can take > 30 minutes), or not. By default, it is set to `FALSE`, to save knitting time. If you set it to `TRUE`, all preprocessing, analysis, and visualization code will be run.

### Data and analysis code

All raw data files are in `/data`, in unprocessed `csv` format, with one exception: the raw naïve listener experiment data contains identifiable information (such as email addresses), so in that case we instead included a processed, de-identified version of the dataset in `/results` (with associated processing code at `/analysis/preprocessing.R`). 

Scripts for preprocessing the data and running the analyses are in `/analysis`. This directory also contains standalone scripts for extracting acoustical data from the audio recordings; to run these, you will need a copy of the full audio corpus, which you can download from <https://doi.org/10.5281/zenodo.5525161>. Note that the audio extraction scripts will *not* be run automatically when knitting the manuscript, even if you set `full_run <- TRUE`.

Preprocessed data, interim datasets, output of models, and the like are in `/results`.

### Visualizations

Visualization code is in `/viz`, along with images and static data used for non-dynamic visualizations. The `/viz/figures` subdirectory contains static images produced by `figures.Rmd`, which can be regenerated with a `full_run` of `manuscript.Rmd`.

### Materials

Research materials are in `/materials`, and include the protocol used at all fieldsites to collect recordings, a table of directional hypotheses for specific audio features in the preregistration, code to run the naïve listener experiment, and supplementary data and materials.

#### Naïve listener experiment

Code for the naïve listener experiment is available in `/materials/naive-listener`. This directory contains two separate versions of the experiment. The first, `naive-listener_Pushkin.js` is the code actually used to collect the data reported in the paper, distributed via Pushkin at <https://themusiclab.org/quizzes/ids>. This code will only run via Pushkin, so it will not execute as-is; we have posted it here for transparency.

The second version, `naive-listener_jsPsych.html`, and associated jsPsych files, is a version of the same experiment converted to run in standalone jsPsych (i.e., without Pushkin or any other software). While this code was not actually used to collect data, we made it to facilitate demonstration of the experiment (using only a fixed set of 16 recordings in the corpus, rather than drawing from the whole corpus). It can be used to understand the structure of the code that *was* used to collect data and is intended for informational/educational purposes. It is not a direct replication of the experiment reported in the paper. To try the demonstration experiment, clone this repository and open `naive-listener_jsPsych.html` in a browser.

#### Supplementary materials

Supplementary data that are not used in the paper, or are only partially analyzed, include`stimuli-rawMetadata.csv`, which contains the manual processing/editing notes of the original raw audio from each fieldsite; `acoustics-meanImputation.csv`, which contains acoustics data cleaned via mean imputation rather than Winsorization; and `fieldsite-supplementaryData.csv` and `PI-survey.pdf`, which contain additional society-level data and the survey used to collect these data.

[![DOI](https://zenodo.org/badge/488404954.svg)](https://zenodo.org/badge/latestdoi/488404954)
