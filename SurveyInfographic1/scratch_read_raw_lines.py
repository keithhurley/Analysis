import os

path1 = r"C:\Users\keith.hurley\.gemini\antigravity\brain\b988a23e-a62e-4f18-acdf-6b68b98c1eab\.system_generated\logs\transcript_full.jsonl"
path2 = r"C:\Users\keith.hurley\.gemini\antigravity\brain\445f4d31-bb17-4395-b8c0-568e2fcb561d\.system_generated\logs\transcript_full.jsonl"

def scan_raw(path):
    if not os.path.exists(path):
        print(f"Path does not exist: {path}")
        return
    print(f"\nScanning {path}...")
    with open(path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            if "CommandLine" in line or "run_command" in line:
                # print first 300 chars of matching line
                print(f"  Line {idx+1}: {line[:300]}...")
                # Search for CommandLine value in the line
                import re
                m = re.search(r'"CommandLine"\s*:\s*"([^"]+)"', line)
                if m:
                    print(f"    CommandLine value: {m.group(1)}")
                else:
                    m2 = re.search(r'"CommandLine"\s*:\s*(\[.*?\])', line)
                    if m2:
                        print(f"    CommandLine array: {m2.group(1)}")

scan_raw(path1)
scan_raw(path2)
