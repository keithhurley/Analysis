import os
import re

search_dir = r"d:\Survey\Analysis"
print("Searching for 'C1Total_days' or 'Total_days' in R scripts...")

matches_count = 0
for root, dirs, files in os.walk(search_dir):
    if ".git" in root or ".gemini" in root:
        continue
    for file in files:
        if file.lower().endswith(('.r', '.rmd')):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.readlines()
                
                matched_lines = []
                for idx, line in enumerate(lines):
                    if "c1total_days" in line.lower() or "total_days" in line.lower():
                        matched_lines.append((idx + 1, line.strip()))
                        
                if matched_lines:
                    print(f"File: {os.path.relpath(file_path, search_dir)}")
                    matches_count += len(matched_lines)
                    for l_num, text in matched_lines[:10]:
                        print(f"  Line {l_num}: {text[:150]}")
                    if len(matched_lines) > 10:
                        print(f"  ... and {len(matched_lines)-10} more matches")
                    print("-" * 50)
            except Exception as e:
                pass

print(f"Found {matches_count} matches in total.")
