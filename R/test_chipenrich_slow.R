test_chipenrich_slow = function(geneset, gpw, n_cores) {
	# Restrict our genes/weights/peaks to only those genes in the genesets.
	# Here, geneset is not all combined, but GOBP, GOCC, etc.
	gpw = subset(gpw, gpw$gene_id %in% geneset@all.genes)

	# Construct model formula.
	model = "peak ~ goterm + s(log10_length,bs='cr')"

	# Run tests. NOTE: If os == 'Windows', n_cores is reset to 1 for this to work
	results_list = parallel::mclapply(as.list(ls(geneset@set.gene)), function(go_id) {
		single_chipenrich_slow(go_id, geneset, gpw, 'chipenrich_slow', model)
	}, mc.cores = n_cores)

	# Collapse results into one table
	results = Reduce(rbind,results_list)

	# Correct for multiple testing
	results$FDR = stats::p.adjust(results$P.value, method = "BH")

	# Create enriched/depleted status column
	results$Status = ifelse(results$Effect > 0, 'enriched', 'depleted')

	results = results[order(results$P.value), ]

	return(results)
}

single_chipenrich_slow = function(go_id, geneset, gpw, method, model) {
	final_model = as.formula(model)

	# Genes in the geneset
	go_genes = geneset@set.gene[[go_id]]

	# Background genes and the background presence of a peak
	b_genes = gpw$gene_id %in% go_genes
	sg_go = gpw$peak[b_genes]

 	# Information about the geneset
	r_go_id = go_id
	r_go_genes_num = length(go_genes)
	r_go_genes_avg_length = mean(gpw$length[b_genes])

    # Information about peak genes
	go_genes_peak = gpw$gene_id[b_genes][sg_go == 1]
	r_go_genes_peak = paste(go_genes_peak, collapse = ", ")
	r_go_genes_peak_num = length(go_genes_peak)

	# Small correction for case where every gene in this geneset has a peak.
	if (all(as.logical(sg_go))) {
		cont_length = quantile(gpw$length, 0.0025)

		cont_gene = data.frame(
			gene_id = "continuity_correction",
			length = cont_length,
			log10_length = log10(cont_length),
			num_peaks = 0,
			peak = 0,
			stringsAsFactors = FALSE)

		if ("mappa" %in% names(gpw)) {
			cont_gene$mappa = 1
		}
		gpw = rbind(gpw,cont_gene)
		b_genes = c(b_genes,1)

		message(sprintf("Applying correction for geneset %s with %i genes...", go_id, length(go_genes)))
	}

    fit = mgcv::gam(final_model, data = cbind(gpw, goterm = as.numeric(b_genes)), family = "binomial")

	# Results from the logistic regression
    r_effect = coef(fit)[2]
    r_pval = summary(fit)$p.table[2, 4]

	out = data.frame(
		"P.value" = r_pval,
		"Geneset ID" = r_go_id,
		"N Geneset Genes" = r_go_genes_num,
		"Geneset Peak Genes" = r_go_genes_peak,
		"N Geneset Peak Genes" = r_go_genes_peak_num,
		"Effect" = r_effect,
		"Odds.Ratio" = exp(r_effect),
		"Geneset Avg Gene Length" = r_go_genes_avg_length,
		stringsAsFactors = FALSE)

	return(out)
}
