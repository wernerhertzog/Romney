# Reference Data

The three CSV files are fixed synthetic comparison datasets with 36
respondents and 103 items. The first column contains respondent identifiers;
the remaining columns are responses. Empty response cells represent NA.

* `synthetic_yesno_36x103.csv`: binary 0/1 responses; 120 missing cells.
* `synthetic_multiple_choice_36x103_k4.csv`: choices 1--4; 106 missing cells.
* `synthetic_ordinal_36x103_1to5.csv`: numeric ratings 1--5; 110 missing cells.

They are not ethnographic observations. `ucinet_results/` contains their
original UCINET 6.832 comparison logs from May 9, 2026, encoded as UTF-16LE.
The original simulation seeds and generator settings are not recorded in
the published repository. The current simulator is tested separately and
must not be used to overwrite these inputs without obtaining new UCINET
reference output.

For complete numerical comparisons and reproduction instructions, see the
installed `validation/` directory or `inst/validation/README.md` in the source.
