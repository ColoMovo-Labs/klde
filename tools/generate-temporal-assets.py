#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Offline original vector artwork; no runtime masks or image generation."""
import math,re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
p=r/'assets/temporal';p.mkdir(exist_ok=True)
palettes={
'clear-morning':['#aaa1dc','#f5d7b4','#f7bd70','#8e88b8','#656c9c','#414e7e','#fff3cc'],
'cloudy-day':['#8dc6eb','#d9eff6','#ffffff','#a1c6d8','#7199b4','#45728f','#fff4b0'],
'sunset':['#8272b3','#f3ae9d','#f39260','#b681aa','#805d90','#4b416f','#ffda9b'],
'rainy-evening':['#526781','#9aafbf','#b6c7ce','#718ba1','#506b87','#334a69','#d4e1e8'],
'starry-night':['#111b42','#33476e','#50638a','#2d3b68','#243252','#172644','#d7e3ff'],
'moonlit-night':['#163f59','#53858c','#82c4bc','#416c7a','#315563','#1d3d51','#d6f3dc']}
for phase,(sky,ground,haze,far,mid,near,orb) in palettes.items():
 stars=''.join(f'<circle cx="{x}" cy="{y}" r="{s}" fill="#e0e9ff" opacity="{o}"/>' for x,y,s,o in [(36,33,1.6,.8),(128,18,1,.6),(208,39,1.5,.9),(258,21,1,.6),(345,30,1.4,.6)]) if phase=='starry-night' else ''
 clouds='<path d="M14 48h53q14 0 14-9t-13-10q-6-17-22-11-11 2-12 14H20q-18 0-6 16Z" fill="#edf5fa" opacity=".6"/><path d="M112 30h38q12 0 10-8t-13-8q-8-12-21-3-4 3-4 7h-10q-14 0 0 12Z" fill="#f4f9ff" opacity=".5"/>' if phase in ('cloudy-day','rainy-evening') else ''
 rain='<path d="M26 58l-4 8m26-9-4 8m26-8-4 8m58-29-4 8m23-5-4 8" stroke="#cedee9" stroke-width="2" stroke-linecap="round" opacity=".65"/>' if phase=='rainy-evening' else ''
 # Original layered land geometry; transparent sky and separate celestial transform.
 (p/(phase+'-land.svg')).write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="480" height="120" viewBox="0 0 480 120"><defs><clipPath id="pill"><rect width="480" height="120" rx="60"/></clipPath></defs><g clip-path="url(#pill)">{stars}{clouds}{rain}<path d="M0 101Q29 90 62 64Q77 52 91 65L139 88Q163 74 188 58Q199 49 213 63L270 96Q330 65 380 79L480 103V120H0Z" fill="{far}"/><path d="M0 104Q47 72 83 85Q107 95 138 91Q176 71 207 88Q252 113 302 93Q358 74 402 101L480 89V120H0Z" fill="{mid}"/><path d="M0 112Q49 96 104 107Q155 124 206 111Q257 100 309 111Q375 123 426 105Q455 96 480 104V120H0Z" fill="{near}"/></g></svg>''')
(p/'moon.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><path d="M44 7a25 25 0 1 0 13 40A25 25 0 0 1 44 7Z" fill="#d6f3dc"/></svg>')
# A dedicated night wallpaper, rather than an opaque veil over the day resource.
(r/'assets/wallpapers/first-night.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="900" viewBox="0 0 1440 900"><defs><linearGradient id="sky" x2="0.8" y2="1"><stop stop-color="#10182f"/><stop offset=".55" stop-color="#25375b"/><stop offset="1" stop-color="#31545f"/></linearGradient><linearGradient id="near" x2=".8" y2="1"><stop stop-color="#344b71"/><stop offset="1" stop-color="#293953"/></linearGradient></defs><rect width="1440" height="900" fill="url(#sky)"/><g fill="#a6bfcb"><circle cx="238" cy="123" r="2"/><circle cx="680" cy="92" r="2"/><circle cx="878" cy="172" r="1.5"/><circle cx="1270" cy="94" r="1.5"/></g><path d="M1120 126a78 78 0 1 0 54 122 78 78 0 0 1-54-122Z" fill="#abcacb"/><path d="M430 648L923 238Q944 217 966 245L1440 684V900H400Z" fill="#344661"/><path d="M816 340L923 238Q944 217 966 245L1070 367L975 336L949 366L915 328L879 367Z" fill="#738da1"/><path d="M0 716L341 342Q372 307 406 347L834 769L1000 900H0Z" fill="#2b405f"/><path d="M262 430L341 342Q372 307 406 347L515 472L406 430L374 458L339 410L299 455Z" fill="#617f92"/><path d="M374 343L406 347L834 769L570 691L421 482Z" fill="#20364f"/><path d="M0 702Q290 592 573 722Q795 831 1052 691Q1270 575 1440 674V900H0Z" fill="url(#near)"/><path d="M0 838Q249 715 516 831Q837 951 1111 817Q1318 736 1440 787V900H0Z" fill="#243a4c"/></svg>''')

def polygon(d):
 t=re.findall(r'[MLQHVZ]|-?\d+(?:\.\d+)?',d);out=[];i=0;cur=(0,0)
 while i<len(t):
  c=t[i];i+=1
  if c in ('M','L'):
   cur=(float(t[i]),float(t[i+1]));i+=2;out.append(cur)
  elif c=='Q':
   control=(float(t[i]),float(t[i+1]));end=(float(t[i+2]),float(t[i+3]));i+=4
   for n in range(1,17):
    v=n/16;out.append(((1-v)**2*cur[0]+2*(1-v)*v*control[0]+v*v*end[0],(1-v)**2*cur[1]+2*(1-v)*v*control[1]+v*v*end[1]))
   cur=end
  elif c=='H':cur=(float(t[i]),cur[1]);i+=1;out.append(cur)
  elif c=='V':cur=(cur[0],float(t[i]));i+=1;out.append(cur)
  elif c!='Z': raise ValueError(c)
 return out
def cross(a,b,v):return (b[0]-a[0])*(v[1]-a[1])-(b[1]-a[1])*(v[0]-a[0])
def clip(points):
 for i,a in enumerate(pill):
  b=pill[(i+1)%len(pill)];src=points;points=[]
  if not src:break
  previous=src[-1];pv=cross(a,b,previous)
  for current in src:
   cv=cross(a,b,current)
   if (cv>=0)!=(pv>=0):
    t=pv/(pv-cv);points.append((previous[0]+t*(current[0]-previous[0]),previous[1]+t*(current[1]-previous[1])))
   if cv>=0:points.append(current)
   previous,pv=current,cv
 return points


def capsule(radius_x):
    points=[(radius_x,0),(480-radius_x,0)]
    for i in range(1,49):
        a=math.radians(-90+i*180/48);points.append((480-radius_x+radius_x*math.cos(a),60+60*math.sin(a)))
    points.append((radius_x,120))
    for i in range(1,49):
        a=math.radians(90+i*180/48);points.append((radius_x+radius_x*math.cos(a),60+60*math.sin(a)))
    return points
for path in list(p.glob('*-land.svg')):
    original=path.read_text()
    for size,width,height in [('compact',160,40),('standard',208,48),('expanded',400,144)]:
        pill=capsule(480*height/width/2)
        def replace(m):
            d=m.group(1)
            if not d.startswith('M0 '):return m.group(0)
            points=clip(polygon(d))
            return '<path d="M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in points)+'Z"'
        result=re.sub(r'<path d="([^"]+)"',replace,original)
        # Keep a size-specific clip path around every layer.  The previous
        # generator only clipped mountain paths whose data started with M0;
        # clouds and rain lines could therefore escape the rounded capsule.
        radius = 480 * height / width / 2
        defs = f'<defs><clipPath id="pill"><rect width="480" height="120" rx="{radius:.2f}"/></clipPath></defs>'
        result = re.sub(r'<defs>.*?</defs>', defs, result)
        (p/(path.stem+'-'+size+'.svg')).write_text(result)
    path.unlink()
