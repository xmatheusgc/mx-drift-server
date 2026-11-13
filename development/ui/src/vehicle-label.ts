type VehicleLabel={model?:string;modelLabel?:string;name?:string};
export const vehicleLabel=(car?:VehicleLabel|null)=>car?.modelLabel||car?.model||'';
export const creationLabel=(car?:VehicleLabel|null)=>car?.name&&car.name!==car.model?car.name:vehicleLabel(car);
