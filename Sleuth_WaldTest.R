# downloading biomaRt and loading the package:
source("https://bioconductor.org/biocLite.R")
biocLite("biomaRt")

suppressMessages({
  library('cowplot')
  library('sleuth')
})

### creation of table containing sample names, condition and path ###
ChenDataTable <- read.csv(file = 'ChenDataTable.csv')


# Code below adapted from slides: 

#### Loading and Initilizing our data ####
# load Sleuth package
library(sleuth)

# read in table (made above), assigned to variable name stab
stab = read.table("ChenDatatable.txt",header=TRUE,stringsAsFactors=FALSE)

# initilize object using sleuth function 
so = sleuth_prep(stab)

### Preforming differential Expression analysis ### 

#fit model comparing the two conditions 
so = sleuth_fit(so, ~condition, 'full')

#fit the reduced model to compare in the likelihood ratio test 
so = sleuth_fit(so, ~1, 'reduced')

#perform the likelihood ratio test for differential expression between conditions 
so = sleuth_lrt(so, 'reduced', 'full')

#preform a wald test
# CFA v Vehicle
so = sleuth_wt(so, which_beta = 'condition.CFA', 'condition.EAE_Vehicle', which_model = 'full')

# CFA v Sephin 
so = sleuth_wt(so, which_beta = 'condition.CFA', 'condition.EAE_Sephin1', which_model = 'full')

# Vehicle v Sephin 
so = sleuth_wt(so, which_beta = 'condition.EAE_Vehicle', 'condition.EAE_Sephin1', which_model = 'full')

### To look at the most signifcant results ###

#load the dplyr package for data.frame filtering
library(dplyr)

#extract the test results from the sleuth object 
sleuth_table = sleuth_results(so, 'reduced:full', 'lrt', show_all = FALSE) 

#filter most significant results (FDR/qval < 0.05) and sort by pval
sleuth_significant = dplyr::filter(sleuth_table, qval <= 0.05) |> dplyr::arrange(pval) 

#print top 10 transcripts
head(sleuth_significant, n=10)

#write FDR < 0.05 transcripts to file
write.table(sleuth_significant, file="Chen1_results.txt",quote = FALSE,row.names = FALSE)

### To get the IDs of the top transcipts ###
#just show transcript, pval, qval (select by column header names) 
head(dplyr::select(sleuth_significant, target_id, pval, qval), n=10)


#### Plot top transcipts ### 

#first extract needed results from kallisto for plotting 
so = sleuth_prep(stab, extra_bootstrap_summary = TRUE, 	read_bootstrap_tpm = TRUE)

#call plot_bootstrap function 
topplot = plot_bootstrap(so, "Chen_data_bootstrap", units = "tpm", 	color_by = "condition") 
topplot

#save plot as PNG file
png("Chen_data.png") 
topplot 
dev.off()

