import argparse
import datacompy
import os
import pandas as pd

parser = argparse.ArgumentParser(description="report")
parser.add_argument('-t','--target',type=str,help='target log file')
parser.add_argument('-r','--reference',type=str,help='reference log file')
args=parser.parse_args()

new_failures_models=pd.DataFrame()
# /somewhere/TRITON_3.0/inductor_log
target_folder = args.target
# /somewhere/TRITON_2.1/inductor_log
reference_folder = args.reference

def get_failures(target_path):
    failures=pd.read_csv(target_path)
    failures=failures.loc[(failures['accuracy'] =='fail_to_run') | (failures['accuracy'] =='eager_two_runs_differ') | (failures['accuracy'] =='infra_error') | (failures['accuracy'] =='eager_1st_run_fail') | (failures['accuracy'] =='fail_accuracy')| (failures['batch_size'] ==0),:]
    return failures.iloc[:, :2]

def str_to_dict(contents):
    res_dict = {}
    for line in contents:
        model = line.split(", ")[0].strip()
        reason = line.strip()
        res_dict[model] = reason
    return res_dict

def parse_acc_failure(file,failed_model,mode):
    key_word = "xpu  eval  " if mode == "eval" else "xpu  train "
    result = []
    found = False
    skip = False
    with open(file, 'r') as reader:
        contents = reader.readlines()
        for line in contents:
            skip = True
            if found ==  False and key_word in line:
                model = line.split(key_word)[1].split(' ')[0].strip()
                if model != failed_model:
                    continue
                found =  True
            if found ==  True and ("Error: " in line or "[ERROR]" in line or "TIMEOUT" in line or "FAIL" in line or "fail_accuracy" in line):
                line=line.replace(',',' ',20)
                result.append(model+", "+ line)
                break
    return result

def failure_parse(model,raw_log,mode):
    content=parse_acc_failure(raw_log,model,mode)
    ct_dict=str_to_dict(content)
    try:
        line = ct_dict[model]
    except KeyError:
        line=model
        pass
    return line


writer = pd.ExcelWriter(os.getcwd()+'/target_hf_accuracy_new_failures.xlsx', engine='xlsxwriter')
for suite in ["huggingface"]:
    for precision in ["amp_bf16","amp_fp16","bfloat16","float16","float32"]:
        for mode in ["training","inference"]:
            target_csv = target_folder + "/" + suite + "/" + precision + "/" + "inductor_" + suite + "_" + precision + "_" + mode + "_" + "xpu_accuracy.csv"
            target_log = target_folder + "/" + suite + "/" + precision + "/" + "inductor_" + suite + "_" + precision + "_" + mode + "_" + "xpu_accuracy.log"
            reference_csv = reference_folder + "/" + suite + "/" + precision + "/" + "inductor_" + suite + "_" + precision + "_" + mode + "_" + "xpu_accuracy.csv"
            target_failures = get_failures(target_csv)
            reference_failures = get_failures(reference_csv)
            failure_compare = datacompy.Compare(target_failures, reference_failures, join_columns='name')
            failure_regression = failure_compare.df1_unq_rows.copy()
            print(f"specific failed models in {suite}_{precision}_{mode}: \n")            
            reason_content=[]
            for model in failure_regression['name'].tolist():
                reason_content.append(failure_parse(model,target_log,mode))
            print(reason_content)
            content = pd.DataFrame({'reason(reference only)': reason_content})
            content.to_excel(writer, sheet_name=f"{suite}_{precision}_{mode}", index=False)
writer.close()
