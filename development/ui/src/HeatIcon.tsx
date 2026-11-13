import React from 'react';
// Original geometric icons, no extracted game textures or logos.
export function HeatIcon({name}:{name:string}){
 const paths:Record<string,React.ReactNode>={
  lock:<><path d="M15 28h34v29H15zM22 28V18a10 10 0 0 1 20 0v10M32 39v9"/></>,
  flight:<><path d="m6 31 50-22-18 48-7-20zM31 37 56 9M13 45l-7 12m18-9-5 9"/></>,
  checkpoint:<><path d="M14 58V8h35l-8 12 8 12H14M8 58h18"/></>,
  door:<><path d="M13 55V24l13-14h25v45zM18 26l11-11h17v15H18M36 37h9"/></>,
  car:<><path d="m8 27 7-12h25l8 12 7 4v13H6V32z"/><path d="M15 27h30M20 15l-3 12m19-12 5 12"/><circle cx="16" cy="44" r="5"/><circle cx="45" cy="44" r="5"/></>,
  tools:<><path d="m15 8 9 10-6 6-10-9v13l9 5 8-3 23 23 6-6-24-23 3-8-5-8z"/><path d="m42 9-5 14 5 5 14-5-8-2 1-11zM37 30 12 54"/></>,
  paint:<><path d="m38 8 15 15-22 22-15-15zM14 34l15 15-11 8L7 45zM35 11l-4 4m8-1 8 8"/><path d="M49 40c-9 11-9 16 0 16s8-6 0-16z"/></>,
  wheel:<><circle cx="32" cy="32" r="23"/><circle cx="32" cy="32" r="17"/><circle cx="32" cy="32" r="5"/><path d="m32 15 0 12m16-1-12 4m6 16-7-10m-13 10 7-10m-13-10 11 4"/></>,
  suspension:<><path d="m22 7 20 0M32 7v10m-9 0 18 6-18 7 18 7-18 7 18 5M32 49v8m-10 0h20"/></>,
  height:<><path d="M12 12v40m-6-6 6 6 6-6M6 18l6-6 6 6M25 20h28M25 44h28M31 24v16m16-16v16"/></>,
  camber:<><path d="M10 52h44M16 13l11-3 12 36-11 4zM45 12v30M41 17l4-5 4 5"/></>,
  track:<><path d="M8 18h10v28H8zm38 0h10v28H46zM18 32h28M23 27l-5 5 5 5m18-10 5 5-5 5"/></>,
  diameter:<><circle cx="32" cy="32" r="21"/><path d="m17 47 30-30m-22 0h22v22M17 25v22h22"/></>,
  tyreWidth:<><path d="M21 10h22v44H21zM25 16h14m-14 8h14m-14 8h14m-14 8h14m-14 8h14M6 32h12m-5-5 5 5-5 5m45-5H46m5-5-5 5 5 5"/></>,
  reset:<><path d="M13 26a21 21 0 1 1 2 22M6 13v16h16"/></>,
  engine:<><path d="M18 19h27l8 9v18H17l-7-9V25h8zM24 12h16m-8 0v7M6 28v14m47-12h5v13h-5"/></>,
  seat:<><path d="M23 9h14v13H23zM23 25v20h23v9H17V25zM39 25l7 15"/></>,
  plate:<><rect x="7" y="20" width="50" height="26" rx="2"/><path d="M14 27v12m7-12v12m7-12v12m8-12v12m8-12v12m6-12v12"/></>,
  light:<><path d="M30 13v38C4 51 4 13 30 13zM39 17h16M39 27h19M39 37h19M39 47h16"/></>,
  person:<><circle cx="32" cy="16" r="9"/><path d="M15 55V39c0-14 34-14 34 0v16M23 55V40m18 15V40"/></>,
  garage:<><path d="M6 25 32 7l26 18v31H6zM15 55V28h34v27M15 35h34m-34 8h34m-34 8h34"/></>,
  settings:<><circle cx="32" cy="32" r="12"/><path d="m27 7 10 0 2 9 8 4 8-3 5 9-6 6 0 9-9 5-1 9-10 2-5-8-8-3-8 3-5-9 6-7 0-9 9-4z"/></>,
 };
 return <svg className="heat-icon" data-icon={name} viewBox="0 0 64 64" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="3" strokeLinejoin="round">{paths[name]??paths.car}</svg>;
}
