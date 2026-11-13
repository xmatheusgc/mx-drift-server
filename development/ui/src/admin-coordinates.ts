export type Coordinate={x:number;y:number;z:number;h:number;target?:string;model?:number;interior?:number;networkId?:number;entity?:number;name?:string;error?:string};
export const coordinateTargets=[['ped','Personagem'],['vehicle','Veículo'],['camera','Câmera']] as const;
export function coordinateText(p:Coordinate,format:'vector3'|'vector4'|'table'){
 if(![p.x,p.y,p.z,p.h].every(Number.isFinite))throw Error('Coordenadas ainda não disponíveis');
 const xyz=[p.x,p.y,p.z].map(v=>v.toFixed(3)),h=((p.h%360+360)%360).toFixed(2);
 if(format==='vector3')return `vector3(${xyz.join(', ')})`;
 if(format==='vector4')return `vector4(${xyz.join(', ')}, ${h})`;
 return `{x=${xyz[0]}, y=${xyz[1]}, z=${xyz[2]}, h=${h}}`;
}
export function parseCoordinates(text:string){
 const fields=text.trim().replace(/^vector[34]\s*\(/i,'').replace(/\)\s*$/,'').split(/[,;\s]+/);
 if(fields.length<3||fields.length>4||fields.some(v=>!/^[-+]?(?:\d+\.?\d*|\.\d+)$/.test(v)))throw Error('Informe X, Y, Z e heading opcional. Use ponto nos decimais.');
 const [x,y,z,h]=fields.map(Number);
 if(![x,y,z].every(Number.isFinite)||Math.abs(x)>20000||Math.abs(y)>20000||z< -100||z>3000||(h!==undefined&&(!Number.isFinite(h)||h<0||h>360)))throw Error('Coordenadas fora dos limites: X/Y ±20000; Z -100 a 3000; heading 0 a 360.');
 return h===undefined?{x,y,z}:{x,y,z,h};
}
