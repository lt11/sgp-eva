## settings -------------------------------------------------------------------

### folder: it would nice to run this script e.g. on hulk:prog/phyb2/yg104-r2
### so that we can match the markdown that goes looking for these data in:
### server_name="hulk"
### dir_server_base="prog/phyb2"
### dir_server_run="${dir_server_base}/yg104-r2"

### phybwt2 parameters:
### tau_par is the threshold of tolerance, optimal at 0.6, while
### k_min is the minimal length of the common substrings,
### 250 is reasonable for genomes
tau_par=0.6
k_min=250
vers_phybwt2="phybwt2-24.7.18"

### base folder, the classic:
### dir_full=$(cd $(dirname "${0}") && pwd)
### dir_base=$(dirname "${dir_full}")
### does not work for a markdown
dir_base=$(dirname "${PWD}")

### working folder (phybwt2 installation folder)
dir_work="${HOME}/tools/phybwt2/${vers_phybwt2}"
### input and output folders
dir_input="${dir_base}/gen/ass"
### clean fai files for phybwt2 (otherwise they are considered as sequences)
if [[ -n "$(find "${dir_input}" -name "*fai" 2>/dev/null)" ]]; then
  find "${dir_input}" -name "*fai" | xargs rm
fi

### in the markdown the dst output folder is created in the chunks above,
### we just make this for the runner
dir_dst_out="${dir_base}/dst"
if [[ ! -d "${dir_dst_out}" ]]; then 
  mkdir -p "${dir_dst_out}"
fi

dir_phy_out="${dir_base}/phy/pb2"
if [[ -d "${dir_phy_out}" ]]; then 
  rm -rf "${dir_phy_out}"
fi
mkdir -p "${dir_phy_out}"

## clmnt ----------------------------------------------------------------------

cd "${dir_work}"

phybwt2-preproc "${dir_input}" "pb2run"
phybwt2 "pb2run.fasta" "pb2run.txt" "pb2run.tree" "${k_min}" "${tau_par}"
distbwt2 "pb2run.fasta" "pb2run.txt" "sim-pb2-wref.txt" "${k_min}"

### cleaning
rm -f "TMP_BinaryVectors"* \
"pb2run.txt" \
"pb2run.fasta" \
"pb2run.fasta.lcp" \
"pb2run.fasta.da" \
"pb2run.fasta.ebwt" \
"pb2run.fasta.cda"

### rename, format, and move the results to output folders
mv -f "pb2run.tree" "pb2-wref.tree"
mv -f "pb2-wref.tree" "${dir_phy_out}"
sed 's|-genome.fa||g' "sim-pb2-wref.txt" > "tmp.txt"
n_strain=$(head -1 "tmp.txt" | sed 's|^\t||')
echo "${n_strain} 12000000" > "sim-pb2-wref.txt"
sed -e '1,1d' "tmp.txt" | sed 's|\t| |g' | sed 's| $||g' >> "sim-pb2-wref.txt"
mv -f "sim-pb2-wref.txt" "${dir_dst_out}"
