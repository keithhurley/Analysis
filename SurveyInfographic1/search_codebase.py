import os
import re

search_dir = r"d:\Survey\Analysis"
keywords = ["preferred", "days fished", "effort", "extrapolat", "species"]

print("Scanning codebase for keywords...")

# List of extensions to search
extensions = ['.r', '.rmd', '.py', '.txt', '.csv']

matches_count = 0
for root, dirs, files in os.walk(search_dir):
    # Skip some folders if necessary
    if ".git" in root or ".gemini" in root:
        continue
    for file in files:
        ext = os.path.splitext(file)[1].lower()
        if ext in extensions:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                
                # Check for keywords
                found_kws = [kw for kw in keywords if re.search(r'\b' + re.escape(kw) + r'\b', content, re.IGNORECASE)]
                if found_kws:
                    # Let's search for species list to make sure it's related
                    has_species = any(s in content.lower() for s in ["bass", "catfish", "crappie", "walleye", "trout"])
                    if len(found_kws) >= 2 or (found_kws and has_species):
                        print(f"File: {os.path.relpath(file_path, search_dir)} matches {found_kws}")
                        matches_count += 1
                        # Print some lines containing the keywords
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if any(re.search(r'\b' + re.escape(kw) + r'\b', line, re.IGNORECASE) for kw in found_kws):
                                print(f"  Line {i+1}: {line.strip()[:120]}")
                        print("-" * 50)
            except Exception as e:
                pass

print(f"Found {matches_count} matching files.")
