# Note: the counts input is to allow future methods to regress on other count data
test_polyenrich_weighted = function(geneset,gpw,n_cores,counts) {
	# Restrict our genes/weights/peaks to only those genes in the genesets.
	# Here, geneset is not all combined, but GOBP, GOCC, etc.
	# i.e. A specific one.
	gpw = subset(gpw,gpw$gene_id %in% geneset@all.genes);
	
	if (sum(gpw$peak) == 0) {
		stop("Error: no peaks in your data!");
	}
	
	if (!(counts %in% names(gpw))) {
		stop(sprintf("Error: %s is not a column in data!", counts))
	}
	
    fitspl = mgcv::gam(as.formula(sprintf("%s~s(log10_length,bs='cr')",counts)),data=gpw,family="nb")
	gpw$spline = as.numeric(predict(fitspl, gpw, type="terms"))
	
	
	# Construct model formula.
	model = sprintf("%s ~ goterm + spline",counts);
	
    # Run tests. NOTE: If os == 'Windows', n_cores is reset to 1 for this to work
    results_list = parallel::mclapply(as.list(ls(geneset@set.gene)), function(go_id) {
        single_polyenrich_weighted(go_id, geneset, gpw, fitspl, 'polyenrich', model)
    }, mc.cores = n_cores)
	
	# Collapse results into one table
	results = Reduce(rbind,results_list)
	
	# Correct for multiple testing
	results$FDR = p.adjust(results$P.value, method="BH");
	
	# Create enriched/depleted status column
	results$Status = ifelse(results$Effect > 0, 'enriched', 'depleted')
	
	results = results[order(results$P.value),];
	
	return(results);
}

single_polyenrich_weighted = function(go_id, geneset, gpw, fitspl, method, model) {
	final_model = as.formula(model);
	
	# Genes in the geneset
	go_genes = geneset@set.gene[[go_id]];
	
	# Filter genes in the geneset to only those in the gpw table.
	# The gpw table will be truncated depending on which geneset type we're in.
	go_genes = go_genes[go_genes %in% gpw$gene_id];
	
	# Background genes and the background presence of a peak
	b_genes = gpw$gene_id %in% go_genes;
	sg_go = gpw$peak[b_genes];
	
	# Information about the geneset
	r_go_id = go_id;
	r_go_genes_num = length(go_genes);
	r_go_genes_avg_length = mean(gpw$length[b_genes]);
	
	# Information about peak genes
	go_genes_peak = gpw$gene_id[b_genes][sg_go==1];
	r_go_genes_peak = paste(go_genes_peak,collapse=", ");
	r_go_genes_peak_num = length(go_genes_peak);
		
	# Logistic regression works no matter the method because final_model is chosen above
	# and the data required from gpw will automatically be correct based on the method used.
	fit = gam(final_model,data=cbind(gpw,goterm=as.numeric(b_genes)),family="nb");
	
	# Results from the logistic regression
	r_effect = coef(fit)[2];
	r_pval = summary(fit)$p.table[2,4];
	
	# The only difference between chipenrich and broadenrich here is
	# the Geneset Avg Gene Coverage column
	
	out = data.frame(
		"P.value"=r_pval,
		"Geneset ID"=r_go_id,
		"N Geneset Genes"=r_go_genes_num,
		"Geneset Peak Genes"=r_go_genes_peak,
		"N Geneset Peak Genes"=r_go_genes_peak_num,
		"Effect"=r_effect,
		"Odds.Ratio"=exp(r_effect),
		"Geneset Avg Gene Length"=r_go_genes_avg_length,
		stringsAsFactors=FALSE);
	
	return(out);
}
