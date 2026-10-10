#!/usr/bin/env python3
"""Import identity-preserving100/101 masters for large Home portraits only.

Keep source aspect ratio, trim insignificant alpha bounds, filter premultiplied
channels, then export straight RGBA with eight transparent pixels of padding.
Existing64px inventory/combat portraits are deliberately not written.
"""
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
for crew in (100,101):
    source=root/f'docs/art-sources/crew-high-resolution/crew-{crew}-master.png'
    image=Image.open(source).convert('RGBA')
    assert min(image.size)>1000 and image.getchannel('A').getextrema()==(0,255)
    image=image.crop(image.getchannel('A').point(lambda a:255 if a>=32 else 0).getbbox())
    scale=min(512/image.width,512/image.height)
    size=(round(image.width*scale),round(image.height*scale))
    image=image.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
    out=Image.new('RGBA',(size[0]+16,size[1]+16))
    out.paste(image,(8,8))
    path=root/f'bin/res/assets/Images/UI/Adventure/Master/Portraits/crew-{crew}.png'
    path.parent.mkdir(parents=True,exist_ok=True)
    out.save(path)
    print(path.relative_to(root),out.size)
