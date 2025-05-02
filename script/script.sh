#!/bin/bash

source activate qiime2-amplicon-2024.5
mkdir ~/qiime2_output
cd ~/qiime2_output
cp ~/GEN711/genome_back/metadata.tsv ~/qiime2_output

qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path /home/users/cjd1179/GEN711/genome_back/manifest.tsv \
 --output-path demux.qza \
 --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv

echo "denoising"

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 15 \
  --p-trunc-len-f 250 \
  --p-trim-left-r 15 \
  --p-trunc-len-r 250 \
  --o-representative-sequences asv-seqs.qza \
  --o-table asv-table.qza \
  --o-denoising-stats stats.qza

echo "denoising complete

qiime metadata tabulate \
  --m-input-file stats.qza \
  --o-visualization stats.qzv

qiime feature-table summarize-plus \
  --i-table asv-table.qza \
  --m-metadata-file metadata.tsv \
  --o-summary asv-table.qzv \
  --o-sample-frequencies sample-frequencies.qza \
  --o-feature-frequencies asv-frequencies.qza

qiime feature-table filter-features \
  --i-table asv-table.qza \
  --p-min-samples 2 \
  --o-filtered-table asv-table-ms2.qza

qiime feature-table filter-seqs \
  --i-data asv-seqs.qza \
  --i-table asv-table-ms2.qza \
  --o-filtered-data asv-seqs-ms2.qza

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences asv-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

qiime feature-classifier classify-sklearn \
  --i-classifier suboptimal-16S-rRNA-classifier.qza \
  --i-reads asv-seqs-ms2.qza \
  --o-classification taxonomy.qza

conda activate q2-boots-amplicon-2025.4

qiime boots kmer-diversity \
  --i-table asv-table-ms2.qza \
  --i-sequences asv-seqs-ms2.qza \
  --m-metadata-file metadata.tsv \
  --p-sampling-depth 96 \
  --p-n 10 \
  --p-replacement \
  --p-alpha-average-method median \
  --p-beta-average-method medoid \
  --output-dir boots-kmer-diversity

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table asv-table-ms2.qza \
  --p-sampling-depth 1103 \
  --m-metadata-file metadata.tsv \
  --output-dir core-metrics-results

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file Metadata.tsv \
  --m-metadata-column replicate \
  --o-visualization core-metrics-results/unweighted-unifrac-replicate-significance.qzv \
  --p-pairwise

echo "pipeline end"
