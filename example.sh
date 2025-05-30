main() {
conda create -n agentless python=3.11 
conda activate agentless
pip install -r requirements.txt
export PYTHONPATH=$PYTHONPATH:$(pwd)
mkdir results

TOPN=3
NUM_THREADS=10

echo ZHENYANG 1.1. FILE LOCALIZE
echo ZHENYANG 1.1.a. LLM
python agentless/fl/localize.py --file_level \
				--output_folder results/swe-bench-lite/file_level \
				--num_threads $NUM_THREADS \
				--skip_existing \
				--backend deepseek --model deepseek-coder 

#echo ZHENYANG 1.1.b. EMBED
#
#python agentless/fl/localize.py --file_level \
#                                --irrelevant \
#                                --output_folder results/swe-bench-lite/file_level_irrelevant \
#                                --num_threads $NUM_THREADS \
#                                --skip_existing \
#				--backend deepseek --model deepseek-coder 
#
#python agentless/fl/retrieve.py --index_type simple \
#                                --filter_type given_files \
#                                --filter_file results/swe-bench-lite/file_level_irrelevant/loc_outputs.jsonl \
#                                --output_folder results/swe-bench-lite/retrievel_embedding \
#                                --persist_dir embedding/swe-bench_simple \
#                                --num_threads $NUM_THREADS
#
#echo ZHENYANG 1.1.c. COMBINE
#python agentless/fl/combine.py  --retrieval_loc_file results/swe-bench-lite/retrievel_embedding/retrieve_locs.jsonl \
#                                --model_loc_file results/swe-bench-lite/file_level/loc_outputs.jsonl \
#                                --top_n $TOPN \
#                                --output_folder results/swe-bench-lite/file_level_combined 

echo ZHENYANG 1.2. ELEMENT LOCALIZE

#                                --start_file results/swe-bench-lite/file_level_combined/combined_locs.jsonl \
python agentless/fl/localize.py --related_level \
                                --output_folder results/swe-bench-lite/related_elements \
                                --top_n $TOPN \
                                --compress_assign \
                                --compress \
                                --start_file results/swe-bench-lite/file_level/loc_outputs.jsonl \
                                --num_threads $NUM_THREADS \
                                --skip_existing 
                                --backend deepseek --model deepseek-coder 

echo ZHENYANG 1.3. LINENO LOCALIZE
python agentless/fl/localize.py --fine_grain_line_level \
                                --output_folder results/swe-bench-lite/edit_location_samples \
                                --top_n $TOPN \
                                --compress \
                                --temperature 0.8 \
                                --num_samples 4 \
                                --start_file results/swe-bench-lite/related_elements/loc_outputs.jsonl \
                                --num_threads $NUM_THREADS \
                                --skip_existing \
                                --backend deepseek --model deepseek-coder 

echo ZHENYANG 1.4. SEPARATE
python agentless/fl/localize.py --merge \
                                --output_folder results/swe-bench-lite/edit_location_individual \
                                --top_n $TOPN \
                                --num_samples 4 \
                                --start_file results/swe-bench-lite/edit_location_samples/loc_outputs.jsonl \
                                --backend deepseek --model deepseek-coder 

#echo ZHENYANG 2. REPAIR
#python agentless/repair/repair.py --loc_file results/swe-bench-lite/edit_location_individual/loc_merged_0-0_outputs.jsonl \
#                                  --output_folder results/swe-bench-lite/repair_sample_1 \
#                                  --loc_interval \
#                                  --top_n=$TOPN \
#                                  --context_window=10 \
#                                  --max_samples 10  \
#                                  --cot \
#                                  --diff_format \
#                                  --gen_and_process \
#                                  --num_threads $NUM_THREADS \
#                                  --backend deepseek --model deepseek-coder
#
}

if [ -z "$OPENAI_API_KEY" ]; then
	echo "export OPENAI_API_KEY=???"
	exit 1
fi
if [ -z "$PROJECT_FILE_LOC" ]; then
	echo "Download proj file and unzip! Then"
	echo "export PROJECT_FILE_LOC=???"
	exit 1
fi
main 2>&1 > logs.txt
