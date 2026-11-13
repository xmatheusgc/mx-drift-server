type Properties=Record<string,any>;

// Compare with the confirmed selection, never with a transient preview.
// Cancellation can then restore the complete saved stance unchanged.
export function resetStanceForWheelChange(current:Properties,next:Properties):Properties{
 const changed=current.wheelType!==next.wheelType||[23,24].some(slot=>(current.mods?.[slot]??-1)!==(next.mods?.[slot]??-1));
 if(!changed||!next.stance)return next;
 return {...next,stance:{...next.stance,wheelSize:1,wheelWidth:1}};
}
