import os
import sys
import json
import traceback
import subprocess
import time
from openai import OpenAI


context = sys.argv[1]
global maxcalls
maxcalls = int(sys.argv[2])
global total_calls
total_calls = 0
try:
    config_path = sys.argv[1]
except IndexError:
    print("Error: Missing config file path argument.")
    print("USAGE: python3 main.py <path_to_config.json> <api_call_limit>")
    sys.exit(1)

try:
    # This block opens the file, reads its content, and parses it
    with open(config_path, 'r') as f:
        context = json.load(f)  # Use json.load() for file objects
except FileNotFoundError:
    print(f"Error: Config file not found at {config_path}")
    sys.exit(1)
except json.JSONDecodeError:
    print(f"Error: Config file {config_path} is not valid JSON.")
    sys.exit(1)


try:
    api_key = os.environ["DEEPSEEK_API_KEY"]
except KeyError:
    print("Error: 'DEEPSEEK_API_KEY' environment variable not set.")
    print("Please set the variable and try again.")
    exit()

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

"""
    Args:
        user_prompt (str): The new message from the user.
        history (list): A list of message dictionaries (from previous turns).
        model_name (str): The DeepSeek model to use.

    Returns:
        str: The AI's response content.
"""

def sanitize(filecontent):
    contentlines = filecontent.split('\n')
    clean_lines = []
    
    for line in contentlines:
        # 1. Remove markdown backticks
        if '`' in line:
            continue # Skip the line entirely
        
        # 2. THIS IS THE FIX: Skip the klee.h include
        if '#include <klee/klee.h>' in line:
            continue # Skip this line
            
        clean_lines.append(line)

    return '\n'.join(clean_lines)

def clean_llm_response(response_content):
    """
    Cleans conversational prefixes and suffixes from the LLM response.
    It finds the first real file path and the last '✶' delimiter.
    """
    
    # 1. Find the start of the *actual* data.
    #    The best anchor is your file path structure.
    start_index = response_content.find("./cwes/")
    
    if start_index == -1:
        # If no file path is found, the response is invalid.
        print("Cleaning Warning: Could not find start anchor './cwes/' in response.")
        return "" # Return empty string

    # 2. Find the end of the *actual* data.
    #    This is the *last* delimiter in the response.
    end_index = response_content.rfind("✶")
    
    if end_index == -1:
        print("Cleaning Warning: Could not find end anchor '✶' in response.")
        return "" # Return empty string

    # 3. Ensure the end is after the start
    if end_index < start_index:
        print("Cleaning Warning: Anchors found in wrong order.")
        return ""

    # 4. Return the clean block of data
    return response_content[start_index : end_index + 1]
        

def implement_response(cwe, llmresponse):
    try:
        commands = llmresponse.split("✶")
        i = 0
        while i < len(commands):
            filepath = commands[i].strip()
            #if context['container'] not in filepath: Ignoring for now..
                #raise ValueError(f"You tried to use a path outside of the designated container! {context['container']}")
            i += 1

            if filepath == "":
                continue

            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            with open(filepath, 'w') as fp:
                content = commands[i].strip()
                fp.write(sanitize(content))
        
            i += 1
    except Exception as e:
        return False, "Response interpreter failed, your response did not follow format (Note, make sure that the paths and the contents are separated by a delimiter too!)" + traceback.format_exc()
    
    try:
        result = subprocess.run(
            ["bash", f"build.sh"], 
            cwd = f"./cwes/{cwe}/output/generated",
            capture_output=True, 
            text=True, 
            check=True
        )
    except subprocess.CalledProcessError as e:
        return False, f"Build script failed with error:\nSTDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}"
    except Exception as e:
        return False, f"Build script failed with error:{traceback.format_exc()}"

    try:
        result = subprocess.run(
            ["bash", f"run_klee.sh"], 
            cwd = f"./cwes/{cwe}/output/generated",
            capture_output=True, 
            text=True, 
            check=True
        )
    except subprocess.CalledProcessError as e:
        return False, f"Build script failed with error:\nSTDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}"
    except Exception as e:
        return False, f"Build script failed with error:{traceback.format_exc()}"

    return True, "Success"

    


def symbolically_execute(cwe, contents):
    global maxcalls
    global total_calls
    first_message = ""
    with open(context['opener']) as fp:
        first_message = fp.read()
    first_message += "\n\n--- START OF CODE ---\n" + contents + "\n--- END OF CODE ---"
    
    history = [{
        "role" : "user",
        "content": first_message
    }]
    print("Intial message sent!")
    
    success = False
    response = ""

    # --- EDIT: Create directories for saving responses ---
    cwe_response_dir = os.path.join("./responses", cwe)
    os.makedirs(cwe_response_dir, exist_ok=True)
    call_attempt = 0
    # --- End of Edit ---

    while not success:
        if total_calls >= maxcalls:
            print("Hit max calls, exiting...")
            sys.exit(1) 
        inputHistory = [{
            "role" : "user",
            "content": first_message
        }]
        if len(history) > 1:
            inputHistory.append(history[-2])
            inputHistory.append(history[-1])

        completion = client.chat.completions.create(
            model='deepseek-chat',
            messages=inputHistory,
            temperature=0.0,
            stream=False
        )
        

        # --- 1. ADDED: Save the prompt to a JSON file ---
        prompt_filename = f"prompt_{call_attempt:03d}.json" # e.g., prompt_001.json
        save_path_prompt = os.path.join(cwe_response_dir, prompt_filename)
        
        try:
            with open(save_path_prompt, 'w', encoding='utf-8') as f:
                # indent=4 creates the "nice" format with newlines
                json.dump(inputHistory, f, indent=4) 
            print(f"Saved LLM prompt to {save_path_prompt}")
        except Exception as e:
            print(f"Warning: Failed to save LLM prompt to {save_path_prompt}. Error: {e}")
        # --- End of Addition ---

        ai_response_message = completion.choices[0].message
        ai_content = ai_response_message.content or "" # Ensure content is not None


        # --- EDIT: Save the LLM response to a file ---
        call_attempt += 1
        response_filename = f"response_{call_attempt:03d}.txt" # e.g., response_001.txt
        save_path = os.path.join(cwe_response_dir, response_filename)
        
        
        try:
            with open(save_path, 'w', encoding='utf-8') as f:
                f.write(ai_content)
            print(f"Saved LLM response to {save_path}")
        except Exception as e:
            print(f"Warning: Failed to save LLM response to {save_path}. Error: {e}")
        # --- End of Edit ---
        history.append({
            "role": ai_response_message.role,
            "content": ai_content
        })

        success, response = implement_response(cwe, clean_llm_response(ai_content))
        print(f"Status {success} Implementation Response: {response} ")
        history.append({
            "role": "user",
            "content": response
        })
        total_calls += 1
        time.sleep(15)


def read_directory(target_path):
    content = ""
    
    for root, dirs, files in os.walk(target_path):
        for filename in files:
            # Construct the full, absolute path
            file_path = os.path.abspath(os.path.join(root, filename))
            if not file_path.endswith(".h") and not file_path.endswith(".cpp")  and not file_path.endswith(".md")  and not file_path.endswith(".c")  and not file_path.endswith(".h")  :
                continue
            if "output/generated" in file_path:
                continue
            try:
                # Open and read the file
                with open(file_path, 'r', encoding='utf-8') as fp:
                    file_content = fp.read()
                    
                    # Print path and content (as in your original function)
                    print(file_path)
                    print(file_content)
                    
                    # Add to the master content string
                    content += file_path + "\n"
                    content += file_content + "\n\n" # Added an extra newline for readability
                    
            except Exception as e:
                # Handle files that can't be read (e.g., binary files, permissions)
                print(f"Warning: Could not read file {file_path}. Error: {e}")
                pass # Skip this file and continue

    return content

def main():
    # --- EDIT: Ensure the main responses directory exists ---
    os.makedirs("./responses", exist_ok=True)
    # --- End of Edit ---
    
    cwes_to_handle = {}
    with os.scandir("./cwes") as items:
        for item in items:
            cwes_to_handle[item.name] = read_directory(item.path)
        
    for cwe in cwes_to_handle.keys():
        symbolically_execute(cwe, cwes_to_handle[cwe])
        print(f"CWE {cwe} has been completed! Waiting 30s...")
        time.sleep(30)
    
if __name__ == "__main__":
    main()