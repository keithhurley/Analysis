import re

with open("tables_with_questions.txt", "r", encoding="utf-8") as f:
    text = f.read()

blocks = text.split("========================================")
print(f"Total tables: {len(blocks) // 2}")

for block in blocks:
    if "TABLE " in block and not "TABLES" in block and not "TABLE INDEX" in block:
        # Find index
        m_idx = re.match(r"\s*TABLE\s+(\d+)", block)
        idx = m_idx.group(1) if m_idx else "?"
        # Find context
        m_ctx = re.search(r"Preceding Context:\s*(.*?)\s*----------------------------------------", block, re.DOTALL)
        ctx = m_ctx.group(1).strip() if m_ctx else "?"
        ctx_lines = [l.strip() for l in ctx.split('\n') if l.strip()]
        last_ctx = ctx_lines[-1] if ctx_lines else "?"
        # Print Table number and summary
        print(f"Table {idx}: {last_ctx[:150]}")
