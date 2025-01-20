## header ---------------------------------------------------------------------

### This script reads a vcf file (e.g. "my-data.vcf") and outputs 
### another vcf, in the same folder (e.g. "my-data-noinv.vcf") after
### filtering out invariant loci. 
### It searches for variable loci, i.e.
### any locus with at least two different alleles in the samples. Thus, a locus 
### where all samples have the alternative allele is filtered out. 
### Same for a locus where all samples have the reference allele.
### Missing genotypes (".") are not considered. Thus, in a 5-samples vcf file
### these invariant (aka constant) loci will be filtered out:
### 1 1 . . 1
### 1 . . . .
### 1 1 1 1 1
### 0 0 0 0 0
### while these variable loci will be retained:
### 0 . 1 . .
### 1 1 1 1 0

rm(list = ls())
library(data.table)
library(scriptName)

## function(s) ----------------------------------------------------------------

VariableLoci <- function(x) {
  unique_vals <- unique(x)
  y <- length(unique_vals[!is.na(unique_vals)]) >= 2
  return(y)
}
### It checks if a vector has 2 or more non-identical elements.
### Arguments:
### (1) x: a vector
###
### Returns:
### (1) y: a boolean, TRUE if the vector has more than 2 
###        or more non-identical elements.

## settings -------------------------------------------------------------------

### script name
myName <- current_filename()

argsVal <- commandArgs(trailingOnly = T)
### check mandatory arguments
if (length(argsVal) < 1) {
  cat("[", myName, "] \n")
  ### stop prints "Error: " in front of the text specified
  stop("no input file provided.\n",
       "Please run the script as 'Rscript no-invariant.R /full/path/my.vcf'.\n",
       domain = NA)
}

### assign the arguments
pathVcf <- argsVal[1]
### dev pathVcf <- "~/Desktop/multis-snps-genfix.vcf"
dirWork <- dirname(pathVcf)
pathOut <- sub(pattern = ".vcf$", replacement = "-noinv.vcf", x = pathVcf)

## clmnt ----------------------------------------------------------------------

### load the input vcf
dtVcf <- fread(file = pathVcf, sep = "\t", na.strings = "antani")
# colnames(dtVcf)[1] <- "CHROM"

### make the header of the output file
strBashHeader <- paste0("grep ^## ", pathVcf, " > ", pathOut)
system(strBashHeader)

### append no-invariant header line
cat("##no-invariant.R removed all invariant sites\n",
    file = pathOut, append = T)

### append column names
strBashHeader <- paste0("grep ^#CHROM ", pathVcf, " >> ", pathOut)
system(strBashHeader)

### remove fields 1-9
dtVcfSamp <- dtVcf[, 10:ncol(dtVcf), with = FALSE]

### find the rank of the GT tag in the FORMAT field:
### e.g. if FORMAT is FRMR:FRMQ:GT:CHRQ:STARTQ:ENDQ the rank is 3
### e.g. if FORMAT is GT:FRMR:FRMQ:CHRQ:STARTQ:ENDQ the rank is 1
inRkGT <- which(unlist(strsplit(dtVcf[1, FORMAT], split = ":")) == "GT")

### select only the GT tag using an anonymous function
dtVcfSamp[, (names(dtVcfSamp)) := lapply(.SD,
                                         \(x) tstrsplit(x,
                                                        ":",
                                                        fixed = T)
                                         [[inRkGT]])]

### fastest and memory efficient conversion of "." to NA
### with another anonymous function
dtVcfSamp[, (names(dtVcfSamp)) := lapply(.SD, \(x) fifelse(x == ".", NA, x))]

### apply VariableLoci to the sample data-table
### and store the boolean result in a vector
blNoInv <- apply(dtVcfSamp, 1, VariableLoci)

### filter the input vcf
dtVcfNoInv <- dtVcf[blNoInv, ]

### append the output
fwrite(x = dtVcfNoInv, file = pathOut, append = T, quote = F,
       sep = "\t", row.names = F, col.names = F)
