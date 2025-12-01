import { Info } from 'lucide-react';
import { useState } from 'react';

export function InfoTooltip({ text }: { text: string }) {
    const [show, setShow] = useState(false);

    return (
        <div className="relative inline-block ml-1">
            <button
                onMouseEnter={() => setShow(true)}
                onMouseLeave={() => setShow(false)}
                className="text-muted-foreground hover:text-foreground transition-colors"
            >
                <Info className="w-4 h-4" />
            </button>
            {show && (
                <div className="absolute z-10 bottom-full left-1/2 -translate-x-1/2 mb-2 w-64 p-3 bg-popover border border-border rounded-lg shadow-lg text-sm text-popover-foreground">
                    {text}
                    <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1 border-4 border-transparent border-t-border"></div>
                </div>
            )}
        </div>
    );
}
