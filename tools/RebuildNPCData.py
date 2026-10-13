"""Rebuild the pinned reference dataset; Python 3, no third-party packages."""
from pathlib import Path
import re, hashlib, urllib.request
root = Path(__file__).resolve().parents[1]
commit = '10393426efe4bbe1de3a31fd071ca36fae358bb6'
url = f'https://raw.githubusercontent.com/tortoise-wow/tortoise-wow/{commit}/sql/base/tw_world_creature_template.sql'
with urllib.request.urlopen(url, timeout=60) as response:
    blob = response.read()
assert hashlib.sha256(blob).hexdigest() == 'a091deb2ed09ffd651d8ae11eac8b40ee11f7505bbcffeae24582fb30f1ed12b'
s = blob.decode('utf-8')
columns = re.findall(r'^  `([^`]+)`', s, re.M)
rows = {}
for block in re.finditer(r'INSERT INTO `creature_template` VALUES (.*?);\s*(?:\n|$)', s, re.S):
    parts=[]; field=''; quoted=False; escape=False; inside=False
    for char in block.group(1):
        if escape: field+=char;escape=False;continue
        if char=='\\' and quoted: escape=True;continue
        if char=="'": quoted=not quoted;continue
        if quoted: field+=char;continue
        if char=='(': inside=True;parts=[];field=''
        elif char==',' and inside: parts.append(field);field=''
        elif char==')' and inside:
            parts.append(field);inside=False
            assert len(parts)==len(columns)
            row=dict(zip(columns,parts));rows[int(row['entry'])]=row
        elif inside: field+=char
assert len(rows)==12751
def lua(text):
    return '"'+text.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n').replace('\r','\\r')+'"'
lines=[f'-- Derived from tortoise-wow creature_template, commit {commit}.',
       '-- AGPL-3.0; see LICENSE and DATA-SOURCES.md. NOT verified OctoWoW live data.',
       '-- [NPC ID] = {detectionRange, enUS name, noProximityAggro}', 'OctoAggroNPCData={']
for key,row in sorted(rows.items()):
    noaggro=int(row['flags_extra'])&2 or row['civilian']=='1'
    lines.append(f'[{key}]={{'+row['detection_range']+','+lua(row['name'])+','+('true' if noaggro else 'false')+'},')
lines.append('}')
(root/'NPCData.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
print('Rebuilt and source-verified 12751 NPC templates.')
