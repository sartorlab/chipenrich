test_fisher_exact = function(geneset,gpw,alternative="two.sided") {
	warning("Fisher's exact test should only be used with the 1kb or 5kb locus definition.")

	# Restrict to only those genes in the genesets.
	gpw = subset(gpw, gpw$gene_id %in% geneset@all.genes)

	genes = gpw$gene_id
	peaks = gpw$peak

	results = lapply(ls(geneset@set.gene), function(go_term) {
		go_genes = geneset@set.gene[[go_term]]
		n_go_genes = length(go_genes)

		in_cat = as.numeric(genes %in% go_genes)
		n_go_peak_genes = sum((genes %in% go_genes) & (peaks == 1))
		xt = table(in_cat, peaks)

		pval = 1
		odds_ratio = 0
		try({
			fet_result = stats::fisher.test(xt, conf.int = FALSE, alternative = alternative)
			pval = fet_result$p.value
			odds_ratio = fet_result$estimate
		}, silent = TRUE)

		go_peak_genes = gpw[(gpw$gene_id %in% go_genes) & (gpw$peak == 1),]$gene_id
		go_peak_genes_str = paste(go_peak_genes, collapse = ", ")

		enr = NA

		if (odds_ratio > 1) {
			enr = "enriched"
		}

		if (odds_ratio < 1) {
			enr = "depleted"
		}

		if (odds_ratio == 0) {
			enr = "depleted"
		}

		if (is.infinite(odds_ratio)) {
			enr = "enriched"
		}

		data.frame(
			"Geneset ID" = go_term,
			"N Geneset Genes" = n_go_genes,
			"N Geneset Peak Genes" = n_go_peak_genes,
			"Geneset Peak Genes" = go_peak_genes_str,
			"Odds.Ratio" = odds_ratio,
			"Status" = enr,
			"P-value" = pval,
			stringsAsFactors = FALSE)
	})

	results = plyr::rbind.fill(results)

	results$FDR = stats::p.adjust(results$P.value, method = "BH")

	results = results[order(results$P.value), ]
	return(results)
}
