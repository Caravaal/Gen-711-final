#!/bin/bash

source activate qiime2-amplicon-2024.5
mkdir ~/qiime2
cd ~/qiime2
wget -O sample-metadata.tsv \
  'https://gut-to-soil-tutorial.readthedocs.io/en/latest/data/gut-to-soil/sample-metadata.tsv'

wget -O demux.qza \
  'https://gut-to-soil-tutorial.readthedocs.io/en/latest/data/gut-to-soil/demux.qza'

wget -O suboptimal-16S-rRNA-classifier.qza \
  'https://gut-to-soil-tutorial.readthedocs.io/en/latest/data/gut-to-soil/suboptimal-16S-rRNA-classifier.qza'

qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 15 \
  --p-trunc-len-f 250 \
  --p-trim-left-r 15 \
  --p-trunc-len-r 250 \
  --o-representative-sequences asv-seqs.qza \
  --o-table asv-table.qza \
  --o-denoising-stats stats.qza

qiime metadata tabulate \
  --m-input-file stats.qza \
  --o-visualization stats.qzv

qiime feature-table summarize-plus \
  --i-table asv-table.qza \
  --m-metadata-file sample-metadata.tsv \
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

qiime feature-classifier classify-sklearn \
  --i-classifier suboptimal-16S-rRNA-classifier.qza \
  --i-reads asv-seqs-ms2.qza \
  --o-classification taxonomy.qza

conda activate q2-boots-amplicon-2025.4

qiime boots kmer-diversity \
  --i-table asv-table-ms2.qza \
  --i-sequences asv-seqs-ms2.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-sampling-depth 96 \
  --p-n 10 \
  --p-replacement \
  --p-alpha-average-method median \
  --p-beta-average-method medoid \
  --output-dir boots-kmer-diversity

echo "pipeline end"
