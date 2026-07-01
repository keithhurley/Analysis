import os
import re

search_dir = r"d:\Survey\Analysis\SurveyInfographic1"
keywords = ["playwright", "puppeteer", "selenium", "chrome", "webshot", "shot", "png", "render", "image"]

print("Scanning SurveyInfographic1 for rendering keywords...")
for root, dirs, files in os.walk(search_dir):
    for file in files:
        if file.endswith(('.py', '.r', '.txt', '.sh', '.bat')):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                found = [kw for kw in keywords if re.search(r'\b' + re.escape(kw) + r'\b', content, re.IGNORECASE)]
                if found:
                    print(f"File {os.path.relpath(file_path, search_dir)} matches: {found}")
            except Exception as e:
                pass
