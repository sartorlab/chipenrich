# For each peak, find the nearest TSS, and distance to it.
peak_nearest_tss = function(peaks, tss) {
	########################################################
	# NOTE: THIS CODE IS RECYCLED FROM assign_peaks() with slight mods to
	# mid_dist_df to match previous output.

	# Determine midpoints of peaks and construct a GRanges object
	# on that basis. Include the peak name for later merging
	peak_mids = IRanges::mid(GenomicRanges::ranges(peaks))
	mids_gr = GenomicRanges::GRanges(
		seqnames = GenomeInfoDb::seqnames(peaks),
		ranges = IRanges::IRanges(start = peak_mids, end = peak_mids),
		name = GenomicRanges::mcols(peaks)$name
	)

	mid_dist_to_ntss = GenomicRanges::distanceToNearest(mids_gr, tss)

	mid_indices = S4Vectors::queryHits(mid_dist_to_ntss)
	tss_indices = S4Vectors::subjectHits(mid_dist_to_ntss)
	mid_dist_df = data.frame(
		chr = GenomeInfoDb::seqnames(mids_gr)[mid_indices],
		peak_midpoint = GenomicRanges::start(mids_gr)[mid_indices],
		nearest_tss = GenomicRanges::start(tss)[tss_indices],
		dist_to_tss = GenomicRanges::mcols(mid_dist_to_ntss)$distance,
		stringsAsFactors = FALSE
	)
	########################################################

	return(mid_dist_df)
}

#' Plot histogram of distance from peak to nearest TSS
#'
#' Create a histogram of the distance from each peak to the nearest transcription
#' start site (TSS) of any gene.
#'
#' @param peaks Either a file path or a \code{data.frame} of peaks in BED-like
#' format. If a file path, the following formats are fully supported via their
#' file extensions: .bed, .broadPeak, .narrowPeak, .gff3, .gff2, .gff, and .bedGraph
#' or .bdg. BED3 through BED6 files are supported under the .bed extension. Files
#' without these extensions are supported under the conditions that the first 3
#' columns correspond to 'chr', 'start', and 'end' and that there is either no
#' header column, or it is commented out. If a \code{data.frame} A BEDX+Y style
#' \code{data.frame}. See \code{GenomicRanges::makeGRangesFromDataFrame} for
#' acceptable column names.
#' @param genome One of the \code{supported_genomes()}.
#'
#' @return A trellis plot object.
#'
#' @examples
#'
#' # Create histogram of distance from peaks to nearest TSS.
#' data(peaks_E2F4, package = 'chipenrich.data')
#' peaks_E2F4 = subset(peaks_E2F4, peaks_E2F4$chrom == 'chr1')
#' plot_dist_to_tss(peaks_E2F4, genome = 'hg19')
#'
#' @export
#' @include constants.R utils.R supported.R setup.R randomize.R
#' @include read.R assign_peaks.R peaks_per_gene.R
plot_dist_to_tss = function(peaks, genome = supported_genomes()) {
	# Get peaks from user's file.
	if (class(peaks) == "data.frame") {
		peakobj = load_peaks(peaks)
	} else if (class(peaks) == "character") {
		peakobj = read_bed(peaks)
	}

	# Load TSS site info.
	tss_code = sprintf("tss.%s", genome)
	data(list = tss_code, package = "chipenrich.data", envir = environment())
	tss = get(tss_code)

	plotobj = ..plot_dist_to_tss(peakobj, tss)
	return(plotobj)
}

..plot_dist_to_tss = function(peaks, tss) {
	# Calculate distance to each TSS.
	tss_peaks = peak_nearest_tss(peaks, tss)

	# Create distance to TSS plot.
	max_dist = max(tss_peaks$dist_to_tss)
	breaks = breaks=c(0, 100, 1000, 5000, 10000, 50000, 100000, max_dist)
	dist_table = table(cut(tss_peaks$dist_to_tss, breaks = breaks))
	dist_table = dist_table / sum(dist_table)
	names(dist_table) = c("< 0.1", "0.1 - 1", "1 - 5", "5 - 10", "10 - 50", "50 - 100", "> 100")

	pf = function(...) {
		args <- list(...)
		bar_labels = sprintf("%0.1f%%", args$y * 100)
		panel.text(seq(1, length(args$x)), args$y + 0.03, bar_labels, cex=1.5)
		panel.barchart(...)
	}

	plotobj = barchart(
		dist_table,
		panel = pf,
		horizontal = FALSE,
		scales = list(rot = 45, cex = 1.6),
		col = "gray",
		ylim = c(0,1),
		ylab = list(label = "Proportion of Peaks", cex=1.65),
		xlab = list(label = "Distance to TSS (kb)", cex=1.65),
		main = list(label = "Distribution of Distance from Peaks to Nearest TSS", cex=1.45)
	)

	return(plotobj)
}
