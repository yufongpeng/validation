# {validation.R}
A simple R script to calculate intra-day accuracy, precision and inter-day accuracy, precision. 

## Computation
### Intra-day

$$\mu_{d} = \sum_{j=1}^{n_r} \dfrac{c_{d, j}}{n_r}$$

$$\sigma_{intra} = s_{intra} = \sqrt{\sum_{i = 1}^{r_d}\sum_{j = 1}^{n_r} \dfrac{(c_{i, j} - \mu_i)^2}{n_d \times (n_r - 1)}}$$

$$accuracy_{intra, d} = \dfrac{\mu_{d}}{conc.}$$

$$precision_{intra, d} = rsd_{intra, d} = \dfrac{\sigma_{intra}}{accuracy_{intra, d}}$$
$n_d$: number of days, $n_r$: number of repeats, $c_{i, j}$: measured concentration of $i$ th day and $j$ th repeat, $conc.$: reference concentration
### Inter-day
$$\mu = \sum_{i = 1}^{n_d}\sum_{j = 1}^{n_r} \dfrac{c_{i, j}}{n_d \times n_r}$$

$$accuracy_{inter} = \sum_{i = 1}^{n_d} \dfrac{accuracy_{intra, i}}{n_d} = \dfrac{\mu}{conc.}$$

$$s_{inter} = \sqrt{\sum_{i = 1}^{n_d} \dfrac{(\mu_i - \mu)^2}{n_d - 1}}$$

$$\sigma_{inter} = \sqrt{max\\{0, s_{inter}^2 - \dfrac{s_{intra}^2}{n_r}\\}}$$

$$precision_{inter} = rsd_{inter} = \dfrac{\sigma_{inter}}{accuracy_{inter}}$$

## Tutorial
Open this file in Rstudio and run the `main` function, a gui will pop up. You can choose one or multiple csv files.
### Input format
The csv files should contain columns of concentration levels and analytes' concentration or accuracy.
The title of columns represented concentration levels should start with "level".
The other columns will be regarded as analytes.
They should be in the following format:

|level1|analyte1|analyte2|level2|analyte3|
|---|---|---|---|---|
|lloq|1|1|2|2| 
||1|2|1|1|
|||.|||
|||.|||
|||.|||
|low|10|10|2|20| 
||1|2|1|1|
|||.|||
|||.|||
|----|----|The next day|----|----|
||1|1|2|2| 
||1|2|1|1|

Repeats should run the fastest, concentration levels run subsequently, and days run the slowest.

Levels can be a string, which input values will be regarded as accuracy or a number which will be regarded as reference concentration.
The name or value can be filled in only the first cell it occured. 

Levels for each analytes are determined by the closet `level` column before the analyte's column. For example, `analyte1` and `analyte2` is `level1`; `analyte3` is `level2`.

The length of levels can be different.

### output format
The out put will be one or multiple csv files depending on configuration settings. The first column is levels; the second column is analyte names; and the other columns are the validation data. For example:
|level|analyte|accuracy.intra.1|std.intra.1|accuracy.intra.2|std.intra.2|rsd.intra.1|rsd.intra.2|accuracy.inter|std.inter|sigma.inter|rsd.inter|
|---|---|---|---|---|---|---|---|---|---|---|---|
lloq|analyte1|1.114|0.074027022|1|0.1|0.075828754|0.0680689|0.075828754|1.087333333|0.07751989|0.075006666|0.068982219|
low|analyte1|1.008|0.038987177|0.972|0.04|0.041793141|0.042997059|0.040973668|1|0.024979992|0.022528994|0.022528994


### Configuration settings
After selecting files and processing, two gui will pop out:
1. "Do you want to combine all analytes into one csv file?"
2. "Do you want to split all analytes into different csv files?"

When the first question is answered "Yes", this program will try to combine all analytes into one csv file. If the number of days are different or it is answered "No", the second question will control if splitting all analytes into different csv files or making analytes stay in the same csv files as before. If different length of levels occur, the file will be automatically splitted.

### Templates
There are 3 csv files in `\exmple`; they can be served as templates and test files.




