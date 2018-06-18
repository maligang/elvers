import os
from os.path import join
import yaml
import numpy as np
import pandas as pd
from snakemake.utils import validate, min_version
from common.params_utils import get_params
min_version("5.1.2") #minimum snakemake version
#validation template: see https://github.com/snakemake-workflows/rna-seq-star-deseq2

# read in & validate sample info 
samples = pd.read_table(config["samples"]).set_index("sample", drop=False)
validate(samples, schema="schemas/samples.schema.yaml")
units = pd.read_table(config["units"], dtype=str).set_index(["sample", "unit"], drop=False)
units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])  # enforce str in index
validate(units, schema="schemas/units.schema.yaml")

# to do: remove this in favor of is_single_end fn, below
units['read_type'] = np.where(units['fq2'].isna(), 'se', 'pe') #PE,SE

def is_single_end(sample, unit, end = ''):
    return pd.isnull(units.loc[(sample, unit), "fq2"]) #    return units.loc[(sample,unit)]['read_type'] == 'se' 

# build file extensions from suffix info (+ set defaults)
base = config.get('basename','eelpond') 
experiment_suffix =config.get('experiment', '')

# build directory info --> later set all these from config file(s)
#folders = config['directories']

OUT_DIR = '{}_out{}'.format(base, experiment_suffix)
LOGS_DIR = join(OUT_DIR, 'logs')
TRIM_DIR = join(OUT_DIR, 'trimmed')
QC_DIR = join(OUT_DIR, 'qc')
ASSEMBLY_DIR = join(OUT_DIR, 'assembly')
QUANT_DIR = join(OUT_DIR, 'quant')

# workflow rules

#fastqc
include: 'rules/fastqc/fastqc.rule'
from rules.fastqc.fastqc_targets import get_targets
fastqc_targs = get_targets(units, base, QC_DIR)
#trimmomatic
include: 'rules/trimmomatic/trimmomatic.rule'
from rules.trimmomatic.trimmomatic_targets import get_targets
trim_targs = get_targets(units, base, TRIM_DIR)
#trinity
include: 'rules/trinity/trinity.rule'
from rules.trinity.trinity_targets import get_targets
trinity_targs = get_targets(units, base, ASSEMBLY_DIR)
#salmon
include: 'rules/salmon/salmon.rule'
from rules.salmon.salmon_targets import get_targets
salmon_targs = get_targets(units, base, QUANT_DIR)

TARGETS = fastqc_targs + trim_targs + trinity_targs + salmon_targs
print(TARGETS)

rule all:
    input: TARGETS 


##### singularity #####

# this container defines the underlying OS for each job when using the workflow
# with --use-conda --use-singularity
singularity: "docker://continuumio/miniconda3"

##### report #####

report: "report/workflow.rst"
