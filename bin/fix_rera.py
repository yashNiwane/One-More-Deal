path = r'lib\screens\auth\profile_setup_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the broken validator line (has literal \r\n strings instead of real newlines)
broken = "validator: (v) => _validateEnglish(\\r\\n                            v,\\r\\n                            fieldName: 'your RERA Number',\\r\\n                            requiredField: false,\\r\\n                          ),"
fixed = "validator: (v) => _validateEnglish(\r\n                            v,\r\n                            fieldName: 'your RERA Number',\r\n                            requiredField: false,\r\n                          ),"

if broken in content:
    content = content.replace(broken, fixed)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed successfully')
else:
    idx = content.find('validator:')
    print('Pattern not found. Current validator area:')
    print(repr(content[idx:idx+300]))
