single_approx = function(go_id, geneset, gpw) {

	lrm.fast = function(x,y) {
		fit = rms::lrm.fit(x,y)
		vv = diag(fit$var)
		cof = fit$coef
		z = cof/sqrt(vv)
		pval = stats::pchisq(z^2, 1, lower.tail = FALSE)
		c(cof[2],pval[2])
	}

	# Genes in the geneset
	go_genes = geneset@set.gene[[go_id]]

	# Background genes, the background presence of a peak, and the background
	# weight of peaks
	b_genes = gpw$gene_id %in% go_genes
	sg_go = gpw$peak[b_genes]
	wg_go = gpw$weight[b_genes]

	# Information about the geneset
	r_go_id = go_id
	r_go_genes_num = length(go_genes)
	r_go_genes_avg_length = mean(gpw$length[b_genes])

    # Information about peak genes
	go_genes_peak = gpw$gene_id[b_genes][sg_go==1]
	r_go_genes_peak = paste(go_genes_peak, collapse = ", ")
	r_go_genes_peak_num = length(go_genes_peak)

	# Small correction for case where every gene in this geneset has a peak.
	if (all(as.logical(sg_go))) {
		cont_length = stats::quantile(gpw$length,0.0025)
		cont_gene = data.frame(
			gene_id = "continuity_correction",
			length = cont_length,
			log10_length = log10(cont_length),
			num_peaks = 0,
			peak = 0,
			weight = stats::quantile(gpw$weight,0.0025),
			prob_peak = stats::quantile(gpw$prob_peak,0.0025),
			resid.dev = stats::quantile(gpw$resid.dev,0.0025),
			stringsAsFactors = FALSE
		)
		if ("mappa" %in% names(gpw)) {
			cont_gene$mappa = 1
		}
		gpw = rbind(gpw,cont_gene)
		b_genes = c(b_genes,1)

		message(sprintf("Applying correction for geneset %s with %i genes...", go_id, length(go_genes)))
	}

	# The model is still essentially peak ~ goterm + s(log10_length,bs='cr')
	# except we're using the weights that are calculated once...
	# Also, y must be binary, so as.numeric(b_genes) (goterm) must be
	# predicted against the weights...
	testm = cbind(y = as.numeric(b_genes), x = gpw$weight*gpw$peak)
	ep = lrm.fast(testm[,"x"], testm[,"y"])

	# Results from quick regression
	r_effect = ep[1]
	r_pval = ep[2]

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

test_approx = function(geneset, gpw, nwp = FALSE, n_cores) {

	if (!"weight" %in% names(gpw)) {
    	stop("Error: you must fit weights first using one of the calc_weights* functions.")
	}

	# Restrict our genes/weights/peaks to only those genes in the genesets.
	gpw = subset(gpw, gpw$gene_id %in% geneset@all.genes)

	# Re-normalize weights.
	# Not sure what nwp means, nor if we want to modify gpw like this.
	if (!nwp) {
		gpw$weight = gpw$weight / mean(gpw$weight)
	} else {
		b_haspeak = gpw$peak == 1
		gpw$weight[b_haspeak] = gpw$weight[b_haspeak] / mean(gpw$weight[b_haspeak])
	}

	# Run tests. NOTE: If os == 'Windows', n_cores is reset to 1 for this to work
	results_list = parallel::mclapply(as.list(ls(geneset@set.gene)), function(go_id) {
		single_approx(go_id, geneset, gpw)
	}, mc.cores = n_cores)

	# Collapse results into one table
	results = Reduce(rbind, results_list)

	# Correct for multiple testing
	results$FDR = stats::p.adjust(results$P.value, method="BH")

	# Create enriched/depleted status column
	results$Status = ifelse(results$Effect > 0, 'enriched', 'depleted')

	results = results[order(results$P.value),]

	return(results)
}
