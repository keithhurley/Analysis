import subprocess
import os
import time

chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# Files to render
print_html = r"d:\Survey\Analysis\SurveyInfographic1\infographic_harvest_print.html"
print_png = r"d:\Survey\Analysis\SurveyInfographic1\infographic_harvest_print.png"

mobile_html = r"d:\Survey\Analysis\SurveyInfographic1\infographic_harvest_mobile.html"
mobile_png = r"d:\Survey\Analysis\SurveyInfographic1\infographic_harvest_mobile.png"

def render_html_to_png(html_path, png_path, width, height):
    # Ensure any existing file is deleted first
    if os.path.exists(png_path):
        os.remove(png_path)
        
    cmd = [
        chrome_path,
        "--headless=new",
        "--disable-gpu",
        f"--window-size={width},{height}",
        f"--screenshot={png_path}",
        f"file:///{html_path.replace(os.sep, '/')}"
    ]
    
    print(f"Rendering: {os.path.basename(html_path)} -> {os.path.basename(png_path)} ({width}x{height})")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("Error during rendering:")
        print(result.stderr)
        return False
        
    # Wait a bit to ensure the file is completely written and visible
    time.sleep(1)
    if os.path.exists(png_path):
        print(f"Success! Saved image to {png_path} (Size: {os.path.getsize(png_path)} bytes)")
        return True
    else:
        print(f"Error: Screenshot file was not created at {png_path}")
        return False

# Render print version
render_html_to_png(print_html, print_png, 1200, 1550)

# Render mobile version
render_html_to_png(mobile_html, mobile_png, 1080, 2580)
