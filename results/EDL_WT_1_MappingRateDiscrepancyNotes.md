**Issue:**  EDL\_WT\_1 uniquely mapped reads is 79.49%, the only significant outlier compared to all other 53 samples and inconsitent wi9th Figure 2a in Liu et al. 2025 that shows all 54 EDL samples mapping above the 95% threshold line.



**Steps Taken**

* Delete EDL\_WT\_1 files, redownload and reprocess from scratch - gave same results, ruling out processing error
* Reviewed FastQC report.  Overrepresented sequences flagged and sequence duplication failed, unlike other 53 samples
* Submitted overrepresented sequence to NCBI BLAST and identified as Equus asinus (donkey) 28s ribosomal RNA with 100% coverage
* Multi-mapping rate is 15.57% vs \~2% in all other samples: consistent with rRNA contamination



**Paper Investigation**

* Paper methods do not mention rRNA filtering , only low-quality read removal and STAR alignment
* No mention of trimming or modification of any sample sequences
* Authors' GitHub repository returns 404
* Corresponded authors contacted twice with no response



**Conclusion:**  Our mapping rate does not match what Figure 2a shows for EDL samples.  The paper does not report what was done to achieve their mapping rates, and all evidence suggest an undocumented rRNA filtering step was applied to this one samples.



**Decision:**  Apply rRNA filtering to EDL\_WT\_1 using SortMeRNA before STAR alignment. Document as an addition to the described methods.

