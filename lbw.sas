
 Project: Malawi LNS vs IFA Randomized Controlled Trial 
 Outcomes:
  - Low birth weight (LBW): birthwt < 2500g (binary)
  - Birth weight in grams (continuous)
 Models 
  - Log-binomial regression for Risk Ratio (RR)
  - Binomial identity-link model for Risk Difference (RD)
  - Linear regression for mean birth weight difference
  - Effect modification by BMI (<18.5 vs >=18.5): interaction + stratified


/* USER SETUP */
%let proj     = YOUR_PROJECT_FOLDER_PATH;         /* e.g., C:\Users\Reshika\malawi_rct */
%let datafile = &proj./data_raw/malawi_rct.csv;   

/* Variable names  */
%let trt   = treat;        /* treatment group: LNS vs IFA */
%let bw    = birthwt;      /* birth weight (grams) */
%let bmi   = bmi;          /* maternal BMI (kg/m^2) */

/*1) IMPORT DATA */
proc import datafile="&datafile"
    out=work.rct_raw
    dbms=csv
    replace;
    guessingrows=max;
run;

proc contents data=work.rct_raw order=varnum;
run;

/* 2) CLEAN + DERIVE OUTCOMES */
data work.rct;
set work.rct_raw;
/* --- Recode treatment to 1=LNS, 0=IFA (edit as needed) --- */
/* If already 0/1, keep as-is. If character, uncomment and adjust:
if upcase(&trt)="LNS" then &trt = 1;
else if upcase(&trt)="IFA" then &trt = 0;
*/

/* LBW indicator */
if not missing(&bw) then do;
    if &bw < 2500 then lbw = 1;
    else lbw = 0;
end;
else lbw = .;

/* BMI category for effect modification: <18.5 vs >=18.5 */
if not missing(&bmi) then do;
    if &bmi < 18.5 then bmi_cat = 0;
    else bmi_cat = 1;
end;
else bmi_cat = .;

label lbw     = "Low birth weight (<2500g)"
      bmi_cat = "BMI category (0:<18.5, 1:>=18.5)";
run;

/* 3) BASIC CHECKS */
proc freq data=work.rct;
tables &trt lbw bmi_cat / missing;
run;

proc means data=work.rct n mean std min p25 median p75 max maxdec=1;
class &trt;
var &bw &bmi;
run;

/*4) RR FOR LBW (LOG-BINOMIAL) */
proc genmod data=work.rct descending;
class &trt (ref="0") / param=ref;
model lbw = &trt / dist=binomial link=log;
estimate "RR: LNS vs IFA" &trt 1 / exp cl;
title "Log-binomial Regression: Risk Ratio for LBW";
run;
title;

/*  5) RD FOR LBW (IDENTITY LINK) */
proc genmod data=work.rct descending;
class &trt (ref="0") / param=ref;
model lbw = &trt / dist=binomial link=identity;
estimate "RD: LNS - IFA" &trt 1 / cl;
title "Binomial Identity Model: Risk Difference for LBW";
run;
title;

/*6) MEAN BIRTH WEIGHT DIFFERENCE (LINEAR REGRESSION) */
proc glm data=work.rct;
class &trt;
model &bw = &trt;
estimate "Mean Difference (LNS - IFA)" &trt 1 -1;
title "Linear Regression: Mean Birth Weight Difference";
run;
quit;
title;

/*7) EFFECT MODIFICATION BY BMI (INTERACTION) */
/* Interaction model for LBW on RR scale */
proc genmod data=work.rct descending;
class &trt (ref="0") bmi_cat (ref="0") / param=ref;
model lbw = &trt bmi_cat &trt*bmi_cat / dist=binomial link=log;
title "Interaction Model: Treatment × BMI Category (LBW, RR scale)";
run;
title;

/* Interaction model for mean birth weight (optional, aligns with stratified table idea) */
proc glm data=work.rct;
class &trt bmi_cat;
model &bw = &trt bmi_cat &trt*bmi_cat;
title "Interaction Model: Treatment × BMI Category (Birth Weight)";
run;
quit;
title;

/* 8) STRATIFIED BY BMI CATEGORY */

/* BMI < 18.5 */
proc genmod data=work.rct(where=(bmi_cat=0)) descending;
class &trt (ref="0") / param=ref;
model lbw = &trt / dist=binomial link=log;
estimate "RR (BMI <18.5): LNS vs IFA" &trt 1 / exp cl;
title "Stratified RR for LBW: BMI < 18.5";
run;
title;

proc glm data=work.rct(where=(bmi_cat=0));
class &trt;
model &bw = &trt;
estimate "Mean Diff (BMI <18.5): LNS - IFA" &trt 1 -1;
title "Stratified Mean Birth Weight: BMI < 18.5";
run;
quit;
title;

/* BMI >= 18.5 */
proc genmod data=work.rct(where=(bmi_cat=1)) descending;
class &trt (ref="0") / param=ref;
model lbw = &trt / dist=binomial link=log;
estimate "RR (BMI >=18.5): LNS vs IFA" &trt 1 / exp cl;
title "Stratified RR for LBW: BMI >= 18.5";
run;
title;

proc glm data=work.rct(where=(bmi_cat=1));
class &trt;
model &bw = &trt;
estimate "Mean Diff (BMI >=18.5): LNS - IFA" &trt 1 -1;
title "Stratified Mean Birth Weight: BMI >= 18.5";
run;
quit;
title;
