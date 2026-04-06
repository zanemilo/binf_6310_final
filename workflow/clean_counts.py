import pandas as pd 
import os
files = os.listdir('../results/counts')
count_files = [f for f in files if f.endswith('.txt')]
count_df = pd.DataFrame()
metadata = pd.DataFrame(
    columns=['tissue_type', 'condition']
)
for file in count_files:
    sample_name = file.split('_counts.txt')[0]
    sample_metadata = pd.DataFrame({
        'sample_name': [sample_name],
        'tissue_type': [sample_name.split('_')[0]],
        'condition': [sample_name.split('_')[1]]
    })
    metadata = pd.concat([metadata, sample_metadata], ignore_index=True, axis=0)
    sample_df = pd.read_csv("../results/counts/"+file, sep='\t', header=1)
    sample_df = sample_df.rename(columns={sample_df.columns[6]: sample_name}).set_index('Geneid').drop(columns=['Chr', 'Start', 'End', 'Strand', 'Length'])
    count_df = pd.concat([count_df, sample_df], axis=1)
    
metadata['condition'] = metadata['condition'].map({'ZBED6' : 'knockout', 'WT' : 'wildtype'})
metadata = metadata.set_index('sample_name')
metadata.to_csv('../results/counts/count_metadata.csv')
count_df.to_csv('../results/counts/all_sample_counts.csv')

