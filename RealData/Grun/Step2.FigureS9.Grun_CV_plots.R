magic.res <- read.csv("/project/mengjiechen/singlecell/data/Grun/grun_magic.csv", header = T)
rownames(magic.res) <- magic.res[, 1]
magic.res <- t(magic.res[, -1])
scimpute.res <- read.csv("/project/mengjiechen/singlecell/data/Grun/scImpute/grun_scimpute_count.csv")
rownames(scimpute.res) <- scimpute.res[, 1]
scimpute.res <- scimpute.res[, -1]

log.scimpute.res <- apply(scimpute.res, 2, function(y){log(y + 0.1)})
log.magic.res <- apply(magic.res, 2, function(y){log(y + 0.1)})

load("/project/mengjiechen/singlecell/summary/grun_drImpute_res")
load("/project/mengjiechen/singlecell/summary/grun_SAVER_res")

log.drimpute.res <- lnpX_imp
log.saver.res <- apply(saver_imp$estimate, 2, function(y){log(y + 0.1)})

load("/project2/mengjiechen/singlecell/revision_summary/grun_impute_ee_res")
res <- imp_ee$imputed

load("/project2/mengjiechen/singlecell/revision_summary/grun_impute_el_ee_res")
log.res2 <- imp_ee$imputed


save(log.drimpute.res, log.scimpute.res, log.magic.res, log.saver.res,  res, log.res2, file = "/project2/mengjiechen/singlecell/revision_summary/Grun_impute_res_summary")


load("/project2/mengjiechen/singlecell/revision_summary/Grun_impute_res_summary")

CV.all <- function(data){
	CV <- function(mean, sd){
      abs(sd/mean)
	}
	CV.per.gene <- apply(data, 1, function(x){
		CV(mean(x), sd(x)) 
	})
	CV.per.gene
}	

drimpute.CV <- CV.all(log.drimpute.res)
scimpute.CV <- CV.all(log.scimpute.res)
magic.CV <- CV.all(log.magic.res)
saver.CV <- CV.all(log.saver.res)
VIPER.CV <- CV.all(res)
VIPER.el.CV <- CV.all(log.res2)


load("/project/mengjiechen/singlecell/data/Grun/grun.rda")
celltype <- gsub("_[0-9]$", "", colnames(gene.expression))
celltype <- gsub("_[0-9][0-9]$", "", celltype)


logxx <- apply(gene.expression, 2, function(y){log(y + 0.1)})
logxx[gene.expression==0] <- 0

CV.nonzero <- function(data){
	CV <- function(mean, sd){
      abs(sd/mean)
	}
	CV.per.gene <- apply(data, 1, function(x){
		CV(mean(x[x!=0]), sd(x[x!=0])) 
	})
	CV.per.gene
}	
raw.cv <- CV.nonzero(logxx)


cell.category <- unique(celltype)
set.seed(5)
show.3000 <- sample(1:length(drimpute.CV), 3000)

library(ggplot2)
library(easyGgplot2)


for(i in 1:4){
	
	flag <- which(celltype%in%cell.category[i])
	raw.data <- logxx[, flag]
	zero.num <- apply(raw.data, 1, function(x){
		length(x[x==0])
	})
	zero.rate <- round(zero.num/ncol(raw.data), 2)*100
	dropout.rate <- apply(raw.data, 1, function(x){
		round(mean(x[x!=0]), 2)
	})
	
	drimpute.CV <- CV.all(log.drimpute.res[, flag])[show.3000]
	scimpute.CV <- CV.all(log.scimpute.res[, flag])[show.3000]
	magic.CV <- CV.all(log.magic.res[, flag])[show.3000]
	saver.CV <- CV.all(log.saver.res[, flag])[show.3000]
	VIPER.CV <- CV.all(res[, flag])[show.3000]
	VIPER.el.CV <- CV.all(log.res2[, flag])[show.3000]
	raw.cv <- CV.nonzero(logxx[, flag])[show.3000]
	zero.rate.selected <- zero.rate[show.3000]
	dropout.rate.selected <- dropout.rate[show.3000]
	
	df <- data.frame(value = c(drimpute.CV, scimpute.CV, magic.CV, saver.CV, VIPER.CV, VIPER.el.CV), method=c(rep("drImpute", 3000), rep("scImpute", 3000), rep("MAGIC", 3000), rep("SAVER", 3000), rep("VIPER-Lasso", 3000), rep("VIPER-Elastic Net", 3000)), compr = rep("Without-imputation", 3000*6), raw = rep(raw.cv, 6), zero = rep(zero.rate.selected, 6), dropout = rep(dropout.rate.selected, 6))
	
	ff <- ggplot2.scatterplot(data = df, xName = 'raw', yName = 'value', size = 0.3, backgroundColor = "white", xtitle="CV (Before Imputation)", ytitle="CV (After Imputation)", mainTitle = cell.category[i], removePanelGrid=TRUE, color = "blue", removePanelBorder=FALSE, showLegend=FALSE, mainTitleFont = c(10, "bold", "black"), xtitleFont = c(15, "bold", "black"),  ytitleFont = c(15, "bold", "black"), xTickLabelFont = c(15, "bold", "white"), yTickLabelFont = c(15, "bold", "black"), facetingFont = c(15, "bold", "black"), facetingRect =  list(background = NULL, lineType = NULL, lineColor = NULL, lineSize = NULL)) + ylim(0, 5)  + xlim(0, 5) + facet_wrap(~method, ncol=3)  + theme(strip.text.x = element_text(size = 15, colour = "black", face = "bold")) + geom_abline(col = "brown", linetype = "dashed", size=1)

   	ggsave(ff, file = paste0("/project/mengjiechen/singlecell/summary_for_paper/plots/Grun_",  cell.category[i], "_CV_comparison.pdf"), width = 12, height = 7)
	
	gg <- ggplot2.scatterplot(data = df, xName = 'raw', yName = 'value', size = 0.3, backgroundColor = "white", xtitle="CV (Before Imputation)", ytitle="CV (After Imputation)", mainTitle = cell.category[i], removePanelGrid=TRUE,   removePanelBorder=FALSE, showLegend=TRUE, legendTitle = "Percentage \n of Zero", legendTitleFont = c(15, "bold", "black"), legendTextFont = c(15, "bold", "black"), mainTitleFont = c(10, "bold", "black"), xtitleFont = c(15, "bold", "black"),  ytitleFont = c(15, "bold", "black"), xTickLabelFont = c(15, "bold", "white"), yTickLabelFont = c(15, "bold", "black"), facetingFont = c(15, "bold", "black"), facetingRect =  list(background = NULL, lineType = NULL, lineColor = NULL, lineSize = NULL)) + geom_point(aes(colour = zero), size = 0.3) + ylim(0, 5)  + xlim(0, 5) + facet_wrap(~method, ncol=3)  + theme(strip.text.x = element_text(size = 15, colour = "black", face = "bold")) + geom_abline(col = "brown", linetype = "dashed", size=1) 

   	ggsave(gg, file = paste0("/project/mengjiechen/singlecell/summary_for_paper/plots/Grun_",  cell.category[i], "_CV_zero_comparison.pdf"), width = 12, height = 7)
	

	
	gg2 <- ggplot2.scatterplot(data = df, xName = 'raw', yName = 'value', size = 0.3, backgroundColor = "white", xtitle="CV (Before Imputation)", ytitle="CV (After Imputation)", mainTitle = cell.category[i], removePanelGrid=TRUE,  removePanelBorder=FALSE, showLegend=TRUE, legendTitle = "Mean of nonzero \n values", legendTitleFont = c(15, "bold", "black"), legendTextFont = c(15, "bold", "black"), mainTitleFont = c(10, "bold", "black"), xtitleFont = c(15, "bold", "black"),  ytitleFont = c(15, "bold", "black"), xTickLabelFont = c(15, "bold", "white"), yTickLabelFont = c(15, "bold", "black"), facetingFont = c(15, "bold", "black"), facetingRect =  list(background = NULL, lineType = NULL, lineColor = NULL, lineSize = NULL)) + geom_point(aes(colour = dropout), size = 0.3) + ylim(0, 5)  + xlim(0, 5) + facet_wrap(~method, ncol=3)  + theme(strip.text.x = element_text(size = 15, colour = "black", face = "bold")) + geom_abline(col = "brown", linetype = "dashed", size=1) 
	
   	ggsave(gg2, file = paste0("/project/mengjiechen/singlecell/summary_for_paper/plots/Grun_",  cell.category[i], "_CV_mean_comparison.pdf"), width = 12, height = 7)
	

}



	  