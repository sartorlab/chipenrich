% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/broadenrich.R
\name{broadenrich}
\alias{broadenrich}
\title{Run Broad-Enrich on broad genomic regions}
\usage{
broadenrich(
  peaks,
  out_name = "broadenrich",
  out_path = getwd(),
  genome = supported_genomes(),
  genesets = c("GOBP", "GOCC", "GOMF"),
  locusdef = "nearest_tss",
  mappability = NULL,
  qc_plots = TRUE,
  min_geneset_size = 15,
  max_geneset_size = 2000,
  randomization = NULL,
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
Windows, etc.) The default value is "broadenrich", and a file "broadenrich_results.tab"
is produced. If \code{qc_plots} is set, then a file "broadenrich_qcplots.png"
is produced containing a number of quality control plots. If \code{out_name}
is set to NULL, no files are written, and results then must be retrieved from
the list returned by \code{broadenrich}.}

\item{out_path}{Directory to which results files will be written out. Defaults
to the current working directory as returned by \code{\link{getwd}}.}

\item{genome}{One of the \code{supported_genomes()}.}

\item{genesets}{A character vector of geneset databases to be tested for
enrichment. See \code{supported_genesets()}. Alternately, a file path to a
a tab-delimited text file with header and first column being the geneset ID
or name, and the second column being Entrez Gene IDs. For an example custom
gene set file, see the vignette.}

\item{locusdef}{One of: 'nearest_tss', 'nearest_gene', 'exon', 'intron', '1kb',
'1kb_outside', '1kb_outside_upstream', '5kb', '5kb_outside', '5kb_outside_upstream',
'10kb', '10kb_outside', '10kb_outside_upstream'. For a description of each,
see the vignette or \code{\link{supported_locusdefs}}. Alternately, a file path for
a custom locus definition. NOTE: Must be for a \code{supported_genome()}, and
must have columns 'chr', 'start', 'end', and 'gene_id' or 'geneid'. For an
example custom locus definition file, see the vignette.}

\item{mappability}{One of \code{NULL}, a file path to a custom mappability file,
or an \code{integer} for a valid read length given by \code{supported_read_lengths}.
If a file, it should contain a header with two column named 'gene_id' and 'mappa'.
Gene IDs should be Entrez IDs, and mappability values should range from 0 and 1.
For an example custom mappability file, see the vignette. Default value is NULL.}

\item{qc_plots}{A logical variable that enables the automatic generation of
plots for quality control.}

\item{min_geneset_size}{Sets the minimum number of genes a gene set may have
to be considered for enrichment testing.}

\item{max_geneset_size}{Sets the maximum number of genes a gene set may have
to be considered for enrichment testing.}

\item{randomization}{One of \code{NULL}, 'complete', 'bylength', or 'bylocation'.
See the Randomizations section below.}

\item{n_cores}{The number of cores to use for enrichment testing. We recommend
using only up to the maximum number of \emph{physical} cores present, as
virtual cores do not significantly decrease runtime. Default number of cores
is set to 1. NOTE: Windows does not support multicore enrichment.}
}
\value{
A list, containing the following items:

\item{opts }{ A data frame containing the arguments/values passed to \code{broadenrich}.}

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
  \item{overlap_start}{ the start position of the peak overlap with the gene locus.}
  \item{overlap_end}{ the end position of the peak overlap with the gene locus.}
  \item{peak_overlap}{ the base pair overlap of the peak with the gene locus.}
}}

\item{peaks_per_gene }{
A data frame of the count of peaks per gene. The columns are:

\describe{
  \item{gene_id}{the Entrez Gene ID. }
  \item{length}{the length of the gene's locus (depending on which locus definition you chose.)}
  \item{log10_length}{the log10(locus length) for the gene.}
  \item{num_peaks}{the number of peaks that were assigned to the gene, given the current locus definition. }
  \item{peak}{whether or not the gene is considered to have a peak, as defined by \code{num_peak_threshold}. }
  \item{peak_overlap}{the number of base pairs of the gene covered by a peak.}
  \item{ratio}{the proportion of the gene covered by a peak.}
}}

\item{results }{
A data frame of the results from performing the gene set enrichment test on
each geneset that was requested (all genesets are merged into one final data
frame.) The columns are:

\describe{
  \item{Geneset.ID}{the identifier for a given gene set from the selected database.  For example, GO:0000003. }
  \item{Geneset.Type}{ specifies from which database the Geneset.ID originates.  For example, "Gene Ontology Biological Process."}
  \item{Description}{ gives a definition of the geneset. For example, "reproduction."}
  \item{P.Value}{the probability of observing the degree of enrichment of the gene set given the null hypothesis that peaks are not associated with any gene sets.}
  \item{FDR}{the false discovery rate proposed by Bejamini \& Hochberg for adjusting the p-value to control for family-wise error rate.}
  \item{Odds.Ratio}{the estimated odds that peaks are associated with a given gene set compared to the odds that peaks are associated with other gene sets, after controlling for locus length and/or mappability.  An odds ratio greater than 1 indicates enrichment, and less than 1 indicates depletion.}
  \item{N.Geneset.Genes}{the number of genes in the gene set.}
  \item{N.Geneset.Peak.Genes}{the number of genes in the genes set that were assigned at least one peak.}
  \item{Geneset.Avg.Gene.Length}{the average length of the genes in the gene set.}
  \item{Geneset.Avg.Gene.Coverage}{the mean proportion of the gene loci in the gene set covered by a peak.}
  \item{Geneset.Peak.Genes}{the list of genes from the gene set that had at least one peak assigned.}

}}
}
\description{
Broad-Enrich is designed for use with broad peaks that may intersect multiple
gene loci, and cumulatively cover greater than 5\% of the genome. For example,
ChIP-seq experiments for histone modifications. For more details, see the
'Broad-Enrich Method' section below. For help choosing a method, see the
'Choosing A Method' section below, or see the vignette.
}
\section{Broad-Enrich Method}{

The Broad-Enrich method uses the cumulative peak coverage of genes in its model
for enrichment: \code{GO ~ ratio + s(log10_length)}. Here, \code{GO} is a
binary vector indicating whether a gene is in the gene set being tested,
\code{ratio} is a numeric vector indicating the ratio of the gene covered by
peaks, and \code{s(log10_length)} is a binomial cubic smoothing spline which
adjusts for the relationship between gene coverage and locus length.
}

\section{Choosing A Method}{

The following guidelines are intended to help select an enrichment function:
\describe{
\item{broadenrich():}{ is designed for use with broad peaks that may intersect
multiple gene loci, and cumulatively cover greater than 5\% of the genome. For
example, ChIP-seq experiments for histone modifications.}
\item{chipenrich():}{ is designed for use with 1,000s or 10,000s of narrow
peaks which results in fewer gene loci containing a peak overall. For example,
ChIP-seq experiments for transcription factors.}
\item{polyenrich():}{ is also designed for narrow peaks, for experiments with
100,000s of peaks, or in cases where the number of binding sites per gene affects
its regulation. If unsure whether to use chipenrich or polyenrich, then we recommend
hybridenrich.}
 \item{hybridenrich():}{ is a combination of chipenrich and polyenrich, to be
used when one is unsure which is the optimal method. }
}
}

\section{Randomizations}{

Randomization of locus definitions allows for the assessment of Type I Error
under the null hypothesis. The randomization codes are:
\describe{
\item{\code{NULL}:}{ No randomizations, the default.}
	\item{'complete':}{ Shuffle the \code{gene_id} and \code{symbol} columns of the
\code{locusdef} together, without regard for the chromosome location, or locus length.
The null hypothesis is that there is no true gene set enrichment.}
	\item{'bylength':}{ Shuffle the \code{gene_id} and \code{symbol} columns of the
\code{locusdef} together within bins of 100 genes sorted by locus length. The null
hypothesis is that there is no true gene set enrichment, but with preserved locus
length relationship.}
	\item{'bylocation':}{ Shuffle the \code{gene_id} and \code{symbol} columns of the
\code{locusdef} together within bins of 50 genes sorted by genomic location. The null
hypothesis is that there is no true gene set enrichment, but with preserved
genomic location.}
}
The return value with a selected randomization is the same list as without.
To assess the Type I error, the \code{alpha} level for the particular data set
can be calculated by dividing the total number of gene sets with p-value < \code{alpha}
by the total number of tests. Users may want to perform multiple randomizations
for a set of peaks and take the median of the \code{alpha} values.
}

\examples{

# Run Broad-Enrich using an example dataset, assigning peaks to the nearest TSS,
# and on a small custom geneset
data(peaks_H3K4me3_GM12878, package = 'chipenrich.data')
peaks_H3K4me3_GM12878 = subset(peaks_H3K4me3_GM12878,
peaks_H3K4me3_GM12878$chrom == 'chr1')
gs_path = system.file('extdata','vignette_genesets.txt', package='chipenrich')
results = broadenrich(peaks_H3K4me3_GM12878, locusdef='nearest_tss',
			genome = 'hg19', genesets=gs_path, out_name=NULL)

# Get the list of peaks that were assigned to genes.
assigned_peaks = results$peaks

# Get the results of enrichment testing.
enrich = results$results

}
\seealso{
Other enrichment functions: 
\code{\link{chipenrich}()},
\code{\link{polyenrich}()}
}
\concept{enrichment functions}
