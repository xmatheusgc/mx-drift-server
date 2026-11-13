export type CameraPose={position:{x:number;y:number;z:number};rotation:{x:number;y:number;z:number};fov:number};
export function rotateCamera(p:CameraPose,dx:number,dy:number,precise=false){
 const next=structuredClone(p),sensitivity=precise?.01:.04;
 next.rotation.x=Math.max(-89,Math.min(89,p.rotation.x-dy*sensitivity));
 next.rotation.z=((p.rotation.z-dx*sensitivity+540)%360)-180;
 return next;
}
export function moveCamera(p:CameraPose,keys:Set<string>,dt:number,speed:number){
 const next=structuredClone(p),pitch=p.rotation.x*Math.PI/180,yaw=p.rotation.z*Math.PI/180;
 const forward=Number(keys.has('KeyW'))-Number(keys.has('KeyS')),right=Number(keys.has('KeyD'))-Number(keys.has('KeyA')),up=Number(keys.has('KeyE'))-Number(keys.has('KeyQ'));
 const norm=Math.max(1,Math.hypot(forward,right,up)),step=Math.min(dt,.05)*speed*(keys.has('ShiftLeft')||keys.has('ShiftRight')?4:1)*(keys.has('ControlLeft')||keys.has('ControlRight')?.25:1)/norm;
 next.position.x+=(-Math.sin(yaw)*Math.cos(pitch)*forward+Math.cos(yaw)*right)*step;
 next.position.y+=(Math.cos(yaw)*Math.cos(pitch)*forward+Math.sin(yaw)*right)*step;
 next.position.z+=(Math.sin(pitch)*forward+up)*step;return next;
}
