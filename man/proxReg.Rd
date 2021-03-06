% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/proxReg.R
\name{proxReg}
\alias{proxReg}
\title{Run Proximity Regulation test on a set of narrow genomic regions}
\usage{
proxReg(
  peaks,
  out_name = "proxReg",
  out_path = getwd(),
  genome = supported_genomes(),
  reglocation = "tss",
  genesets = c("GOBP", "GOCC", "GOMF"),
  randomization = NULL,
  qc_plots = TRUE,
  min_geneset_size = 15,
  max_geneset_size = 2000,
  n_cores = 1
)
}
\arguments{
\item{peaks}{Either a file path or a \code{data.frame} of peaks in BED-like
format. If a file path, the following formats are fully supported via their
file extensions: .bed, .broadPeak, .narrowPeak, .gff3, .gff2, .gff, and .bedGraph
or .bdg. BED3 through BED6 files are supported under the .bed extension. Files
without these extensions are supported under the conditions that the first 3
columns correspond to 'chr', 'start', and 'end' and that there is either no
header column, or it is commented out. If a \code{data.frame} A BEDX+Y style
\code{data.frame}. See \code{GenomicRanges::makeGRangesFromDataFrame} for
acceptable column names.}

\item{out_name}{Prefix string to use for naming output files. This should not
contain any characters that would be illegal for the system being used (Unix,
Windows, etc.) The default value is "proxReg", and a file "proxReg_results.tab"
is produced. If \code{qc_plots} is set, then a file "proxReg_qcplots.pdf"
is produced containing a number of quality control plots. If \code{out_name}
is set to NULL, no files are written, and results then must be retrieved from
the list returned by \code{proxReg}.}

\item{out_path}{Directory to which results files will be written out. Defaults
to the current working directory as returned by \code{\link{getwd}}.}

\item{genome}{One of the \code{supported_genomes()}. If reglocation = enhancer,
genome MUST be 'hg19'.}

\item{reglocation}{One of: 'tss', 'enhancer'. Details in the "Regulatory locations" section}

\item{genesets}{A character vector of geneset databases to be tested for
enrichment. See \code{supported_genesets()}. Alternately, a file path to
a tab-delimited text file with header and first column being the geneset ID
or name, and the second column being Entrez Gene IDs. For an example custom
gene set file, see the vignette.}

\item{randomization}{One of: 'shuffle', 'unif', 'bylength', 'byenh'. These were used to
test for Type I error under the null hypothesis. A general user will never have to
use these.}

\item{qc_plots}{A logical variable that enables the automatic generation of
plots for quality control.}

\item{min_geneset_size}{Sets the minimum number of genes a gene set may have
to be considered for testing.}

\item{max_geneset_size}{Sets the maximum number of genes a gene set may have
to be considered for testing.}

\item{n_cores}{The number of cores to use for testing. We recommend
using only up to the maximum number of \emph{physical} cores present, as
virtual cores do not significantly decrease runtime. Default number of cores
is set to 1. NOTE: Windows does not support multicore testing.}
}
\value{
A list, containing the following items:

\item{opts }{A data frame containing the arguments/values passed to \code{polyenrich}.}

\item{peaks }{
A data frame containing peak assignments to genes. Peaks which do not overlap
a gene locus are not included. Each peak that was assigned to a gene is listed,
along with the peak midpoint or peak interval coordinates (depending on which
was used), the gene to which the peak was assigned, the locus start and end
position of the gene, and the distance from the peak to the TSS.

The columns are:

\describe{
  \item{peak_id}{an ID given to unique combinations of chromosome, peak start, and peak end. }
  \item{chr}{the chromosome the peak originated from. }
  \item{peak_start}{start position of the peak. }
  \item{peak_end}{end position of the peak. }
  \item{gene_id}{the Entrez ID of the gene to which the peak was assigned. }
  \item{gene_symbol}{the official gene symbol for the gene_id (above). }
  \item{gene_locus_start}{the start position of the locus for the gene to which the peak was assigned (specified by the locus definition used.) }
  \item{gene_locus_end}{the end position of the locus for the gene to which the peak was assigned (specified by the locus definition used.) }
  \item{nearest_tss}{the closest TSS to this peak (for any gene, not necessarily the gene this peak was assigned to.) }
  \item{dist_to_tss}{the distance in bp to the closest TSS to this peak. }
  \item{nearest_tss_gene}{the gene having the closest TSS to the peak (should be the same as gene_id when using the nearest TSS locus definition.) }
  \item{nearest_tss_gene_strand}{the strand of the gene with the closest TSS. }
  \item{log_dtss}{ log of dist_to_tss}
  \item{log_gene_ll}{the log of length of the gene locus in bp }
  \item{scaled_dtss}{the adjusted distance to TSS, used in the calculations. Shown if reglocation = "tss" }
  \item{dist_to_enh}{the distance to the nearest enhancer. Shown if reglocation = "enhancer" }
  \item{avg_denh}{the empirical average for distance to the nearest enhancer for the gene the peak is assigned to. Shown if reglocation = enhancer }
  \item{scaled_denh}{the adjusted distance to the nearest enhancer. Shown if reglocation = enhancer }
}}

\item{results }{
A data frame of the results from performing the proxReg test on
each geneset that was requested (all genesets are merged into one final data
frame.) The columns are:

\describe{
  \item{Geneset.ID}{the identifier for a given gene set from the selected database.  For example, GO:0000003. }
  \item{Geneset.Type}{ specifies from which database the Geneset.ID originates.  For example, "Gene Ontology Biological Process."}
  \item{Description}{ gives a definition of the geneset. For example, "reproduction."}
  \item{P.Value}{the probability of observing the proxmity of genomic regions in the gene set given the null hypothesis that peaks are not closer or farther in the gene set.}
  \item{FDR}{the false discovery rate proposed by Bejamini \& Hochberg for adjusting the p-value to control for family-wise error rate.}
  \item{Effect}{the signed Wilcoxon statistic, with positive values meaning the gene set has closer genomic regions than expected by chance.}
  \item{Status}{specifies if the peaks in the gene set tend to be closer or farther than those not in the gene set.}
  \item{Odds.Ratio}{the estimated odds that peaks are associated with a given gene set compared to the odds that peaks are associated with other gene sets, after controlling for locus length and/or mappability.  An odds ratio greater than 1 indicates enrichment, and less than 1 indicates depletion.}
  \item{N.Geneset.Genes}{the number of genes in the gene set.}
  \item{N.Geneset.Peak.Genes}{the number of genes in the genes set that were assigned at least one peak.}
  \item{Geneset.Peak.Genes}{the list of genes from the gene set that had at least one peak assigned.}
}}
}
\description{
This method is designed for a set of narrow genomic regions (e.g. TF peaks) and is used to test
whether the genomic regions assigned to genes in a gene set are closer to 
regulatory locations (i.e. promoters or enhancers) than by chance.
}
\section{Regulatory locations}{

Current supported regulatory locations are gene transcription
start sites (tss) or enhancer locations (hg19 only)
}

\section{Method}{

ProxReg first calculates the distance between each peak midpoint and 
regulatory location in base pairs. For gene transcription start sites, 
since parts of the chromosome are more sparse than others, there is an
association with gene locus length that needs to be adjusted for.
When using tss as the regulatory location, the peak distances are 
adjusted for this confounding variable based on an average of 90 ENCODE
ChIP-seq experiments (details in citation pending). Similarly, for enhancers, 
distances depend on the density of enhancers within a gene locus, so distance
to enhancer is adjusted using an empirical average of 90 ChIP-seq ENCODE
experiments.

For each gene set of interest, the genomic regions are divided into two groups indicating
the gene with the nearest tss is in the gene set or not. A Wilcoxon Rank-Sum test is 
then done to test for a difference in the adjusted distances (either to tss or enhancer).
}

\examples{
# Run proxReg using an example dataset, assigning peaks to the nearest TSS,
# and on a small custom geneset
data(peaks_E2F4, package = 'chipenrich.data')
peaks_E2F4 = subset(peaks_E2F4, peaks_E2F4$chrom == 'chr1')
gs_path = system.file('extdata','vignette_genesets.txt', package='chipenrich')
results = proxReg(peaks_E2F4, reglocation = 'tss',
			genome = 'hg19', genesets=gs_path, out_name=NULL)

# Get the list of peaks that were assigned to genes and their distances to 
# regulatory regions.
assigned_peaks = results$peaks

# Get the results of enrichment testing.
enrich = results$results

}
