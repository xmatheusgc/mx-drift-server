import {type ReactNode} from 'react';
export function SettingsRow({label,description,children}:{label:string;description:string;children:ReactNode}){
 return <label className="settings-row"><strong>{label}</strong><div className="settings-value">{children}</div><span className="settings-description">{description}</span></label>;
}
