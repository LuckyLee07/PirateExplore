#!/usr/bin/env python3
"""Native economic and ownership counterfactuals in isolated source overlays.
The normal runner builds a surfaceless native binary first. No worktree source,
profile, desktop, billing bridge or network service is modified by this test.
"""
from pathlib import Path
import os, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
folder=Path(os.environ.get('COHERENT_SHORTAGE_CAPTURE_DIR','/workspace/shared/pirate-audit/coherent-shortage-owners'))
native=folder/'shortage-owners-native'
assert native.is_file(), 'Run coherent_shortage_ownership_render.py first'
mutations=[
 ('return-unowned','Explore.lua','addDiamond(-price,nil,nil,presentation)','addDiamond(-price)', 'actual owned WarmDialog'),
 ('talent-unowned','DataManager.lua','self:addDiamond(-needDiamod, nil, nil, presentation)','self:addDiamond(-needDiamod)', 'actual owned WarmDialog'),
 ('mission-unowned','MissionManagers.lua','addDiamond(-self.price, nil, nil, presentation)','addDiamond(-self.price)', 'actual owned WarmDialog'),
 ('return-price','Explore.lua','addDiamond(-price,nil,nil,presentation)','addDiamond(-price-1,nil,nil,presentation)', 'exact shipped return price'),
 ('talent-price','DataManager.lua','local diamond = tonumber(value[dataKeyResumeNum])','local diamond = tonumber(value[dataKeyResumeNum])+1', 'exact shipped talent price'),
 ('mission-price','MissionManagers.lua','addDiamond(-self.price, nil, nil, presentation)','addDiamond(-self.price-1, nil, nil, presentation)', 'exact shipped mission price'),
 ('row-rebind','IntelligencePresentation.lua','function()if allowed()then callback()end end','function()callback()end','retained rebound row cannot replace presentation'),
]
with tempfile.TemporaryDirectory(prefix='pirate-intelligence-mutations-') as tmp:
 shadow=Path(tmp);(shadow/'bin/res').mkdir(parents=True)
 shutil.copytree(root/'bin/res/scripts',shadow/'bin/res/scripts')
 for name in ('src','tools'):(shadow/name).symlink_to(root/name,target_is_directory=True)
 (shadow/'bin/res/assets').symlink_to(root/'bin/res/assets',target_is_directory=True)
 for name,filename,before,after,expected in mutations:
  path=shadow/'bin/res/scripts/LuaClass'/filename;source=(root/'bin/res/scripts/LuaClass'/filename).read_text();assert before in source
  path.write_text(source.replace(before,after))
  run=subprocess.run([str(native),'tools/tests/coherent_intelligence_return_ownership_native.lua'],cwd=shadow,env=os.environ.copy(),text=True,capture_output=True,timeout=120)
  output=run.stdout+run.stderr;(folder/(name+'-counterfactual.log')).write_text(output)
  path.write_text(source)
  assert run.returncode and expected in output, name+' did not fail its expected assertion: '+output[-1800:]
  print('PASS native counterfactual rejected: '+name)
