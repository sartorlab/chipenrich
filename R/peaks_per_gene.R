# Used in plot_expected_peaks(...) and chipenrich(...)
#' Aggregate peak assignments over the \code{gene_id} column
#'
#' For each \code{gene_id}, determine the locus length and the number of peaks.
#'
#' Typically, this function will not be used alone, but inside \code{chipenrich()}.
#'
#' @param assigned_peaks A \code{data.frame} resulting from \code{assign_peaks()} or \code{assign_peak_segments()}.
#' @param locusdef A locus definition object from \code{chipenrich.data}.
#' @param mappa A mappability object from \code{chipenrich.data}.
#'
#' @return A \code{data.frame} with columns \code{gene_id, length, log10_length, num_peaks, peak}. The result is used directly in the gene set enrichment tests in \code{chipenrich()}.
#'
#' @examples
#'
#' data('locusdef.hg19.nearest_tss', package = 'chipenrich.data')
#' data('tss.hg19', package = 'chipenrich.data')
#'
#' file = system.file('extdata', 'test_assign.bed', package = 'chipenrich')
#' peaks = read_bed(file)
#'
#' assigned_peaks = assign_peaks(
#' 	peaks = peaks,
#' 	locusdef = locusdef.hg19.nearest_tss,
#' 	tss = tss.hg19)
#'
#' ppg = num_peaks_per_gene(
#' 	assigned_peaks = assigned_peaks,
#' 	locusdef = locusdef.hg19.nearest_tss,
#' 	mappa = NULL)
#'
#' @export
num_peaks_per_gene = function(assigned_peaks, locusdef, mappa=NULL) {
	# Add in gene lengths to locusdef data
	# NOTE: the locusdef@dframe is the basis for the returned object because
	# the enrichment tests need to know which genes have no peaks as well as
	# which genes have peaks. The assigned_peaks object just tells us which
	# peaks overlapped a locus.
	d = locusdef@dframe
	d$length = d$end - d$start

	# Sum up lengths for each gene.
	d = stats::aggregate(length ~ gene_id, d, sum)
	d$log10_length = log10(d$length+1)

	# Compute the total number of peaks assigned to each gene.
	ppg = table(assigned_peaks$gene_id)
	d_ppg = data.frame(
		gene_id = names(ppg),
		num_peaks = as.numeric(ppg),
		stringsAsFactors = FALSE)
	result = merge(
		x = d,
		y = d_ppg,
		by = 'gene_id',
		all.x= TRUE)
	result[is.na(result$num_peaks), ]$num_peaks = 0

	# Mappable length if requested
	if (!is.null(mappa)) {
		message("Mappability adjustment is enabled..")
		result = merge(
			x = result,
			y = mappa,
			by = 'gene_id',
			sort= FALSE)
		result$length = as.numeric((result$mappa * result$length) + 1)
		result$log10_length = log10(result$length)
	}

	# Order by number of peaks in a gene.
	result = result[order(result$num_peaks, decreasing= TRUE), ]

	# Add in peak vector (0,1).
	result$peak = as.numeric(result$num_peaks >= 1)

	return(result)
}

# Used for method='broadenrich'
#' Add peak overlap and ratio to result of \code{num_peaks_per_gene()}
#'
#' In particular, for \code{method = 'broadenrich'} in \code{chipenrich()}, when using \code{assign_peak_segments()}. This function will add aggregated \code{peak_overlap} (in base pairs) and \code{ratio} (relative to \code{length}) columns to the result of \code{num_peaks_per_gene()} so the right data is present for the \code{method = 'broadenrich'} model.
#'
#' Typically, this function will not be used alone, but inside \code{chipenrich()} with \code{method = 'broadenrich'}.
#'
#' @param assigned_peaks A \code{data.frame} resulting from \code{assign_peak_segments()}.
#' @param ppg The aggregated peak assignments over \code{gene_id} from \code{num_peaks_per_gene()}.
#'
#' @return A \code{data.frame} with columns \code{gene_id, length, log10_length, num_peaks, peak, peak_overlap, ratio}. The result is used directly in the gene set enrichment tests in \code{chipenrich()} when \code{method = 'broadenrich'}.
#'
#' @examples
#'
#' data('locusdef.hg19.nearest_tss', package = 'chipenrich.data')
#' data('tss.hg19', package = 'chipenrich.data')
#'
#' file = system.file('extdata', 'test_assign.bed', package = 'chipenrich')
#' peaks = read_bed(file)
#'
#' assigned_peaks = assign_peak_segments(
#' 	peaks = peaks,
#' 	locusdef = locusdef.hg19.nearest_tss)
#'
#' ppg = num_peaks_per_gene(
#' 	assigned_peaks = assigned_peaks,
#' 	locusdef = locusdef.hg19.nearest_tss,
#' 	mappa = NULL)
#'
#' ppg = calc_peak_gene_overlap(
#' 	assigned_peaks = assigned_peaks,
#' 	ppg = ppg)
#'
#' @export
calc_peak_gene_overlap = function(assigned_peaks, ppg) {
	# Sum up the lengths for each peak in a gene
	rpg = stats::aggregate(peak_overlap ~ gene_id, assigned_peaks, sum)

	d_rpg = data.frame(
		gene_id = rpg$gene_id,
		peak_overlap = rpg$peak_overlap,
		stringsAsFactors = FALSE)
	result = merge(
		x = ppg,
		y = d_rpg,
		by = 'gene_id',
		all.x= TRUE)
	result$peak_overlap[is.na(result$peak_overlap)] = 0

	result$ratio = result$peak_overlap / result$length

	result$ratio[result$ratio > 1] = 1

	# Order by number of peaks in a gene.
	result = result[order(result$num_peaks,decreasing= TRUE),]

	return(result)
}

# Used for method='chipapprox'
# Identical to post-mappa part of calc_weights_chipenrich(...)
# Adds weight, prob_peak, resid.dev columns to peaks per gene result
calc_approx_weights = function(ppg, mappa) {
	d = ppg

	# Create model.
	model = "peak ~ s(log10_length, bs = 'cr')"

	# Compute binomial spline fit.
	fit = gam(as.formula(model), data = d, family = 'binomial')

	# Compute weights for each gene, based on the predicted prob(peak) for each gene.
	ppeak = fitted(fit)
	w0 = 1 / (ppeak/mean(d$peak,na.rm= TRUE))
	w0 = w0 / mean(w0,na.rm= TRUE)

	d$weight = w0
	d$prob_peak = ppeak
	d$resid.dev = resid(fit,type="deviance")

	cols = c("gene_id","length","log10_length","mappa","num_peaks","peak","weight","prob_peak","resid.dev")
	if (is.null(mappa)) {
		cols = setdiff(cols,c("mappa"))
	}
	d = subset(d,select=cols)

	return(d)
}
