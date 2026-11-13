import {forwardRef,type ReactNode} from 'react';
export const OptionStrip=forwardRef<HTMLDivElement,{label:string;children:ReactNode;className?:string;count?:number;role?:string}>(function OptionStrip({label,children,className='',count,role},ref){
 return <div ref={ref} className={'option-strip '+className} data-count={count} role={role} aria-label={label} onWheel={event=>{const el=event.currentTarget;if(el.scrollWidth>el.clientWidth){event.preventDefault();el.scrollLeft+=event.deltaY+event.deltaX;}}}>{children}</div>;
});
