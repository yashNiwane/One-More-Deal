import sys

file_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\properties\properties_feed_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out_lines = []
skip = False

for i, line in enumerate(lines):
    if 'double get minExtent => 100;' in line:
        out_lines.append(line.replace('100', '60')) # 40 for SegmentedFilter + 16 vertical padding + 4 bottom spacing
        continue
    if 'double get maxExtent => 100;' in line:
        out_lines.append(line.replace('100', '60'))
        continue

    if 'SizedBox(' in line and 'height: 30,' in lines[i+1] and 'ListView(' in lines[i+2]:
        skip = True
    
    if skip:
        if line.strip() == '),' and 'const SizedBox(height: 4),' in lines[i+1]:
            skip = False
            continue
        continue
    
    out_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(out_lines)

print("PropertiesFeedScreen updated")
