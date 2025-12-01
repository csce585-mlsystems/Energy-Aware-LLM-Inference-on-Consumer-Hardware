import { X } from 'lucide-react';

interface ComparisonData {
    run1: any;
    run2: any;
}

export function ComparisonView({ comparison, onClose }: { comparison: ComparisonData, onClose: () => void }) {
    const { run1, run2 } = comparison;

    const calculateDiff = (val1: number, val2: number) => {
        const diff = ((val2 - val1) / val1) * 100;
        return diff;
    };

    const DiffBadge = ({ val1, val2, inverse = false }: { val1: number, val2: number, inverse?: boolean }) => {
        const diff = calculateDiff(val1, val2);
        const isPositive = inverse ? diff < 0 : diff > 0;
        const color = isPositive ? 'text-red-400' : 'text-green-400';
        const sign = diff > 0 ? '+' : '';
        return <span className={`text-sm font-mono ${color}`}>({sign}{diff.toFixed(1)}%)</span>;
    };

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-card border rounded-lg max-w-4xl w-full p-6 max-h-[80vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-6">
                    <h2 className="text-2xl font-bold">Run Comparison</h2>
                    <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
                        <X className="w-6 h-6" />
                    </button>
                </div>

                <div className="grid grid-cols-2 gap-6">
                    <div className="space-y-4">
                        <div className="border-b border-border pb-2">
                            <h3 className="text-lg font-semibold">Run 1: {run1.run_id}</h3>
                            <span className={`px-2 py-1 rounded text-xs font-bold ${run1.backend === 'gpu' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'
                                }`}>
                                {run1.backend.toUpperCase()}
                            </span>
                        </div>
                        <div className="space-y-3">
                            <div>
                                <p className="text-sm text-muted-foreground">Latency</p>
                                <p className="text-2xl font-mono">{Math.round(run1.latency_ms)} ms</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Energy</p>
                                <p className="text-2xl font-mono text-yellow-400">{Math.round(run1.energy_joules)} J</p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">EDP</p>
                                <p className="text-2xl font-mono text-blue-400">
                                    {(run1.latency_ms * run1.energy_joules / 1000).toFixed(1)} k
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="space-y-4">
                        <div className="border-b border-border pb-2">
                            <h3 className="text-lg font-semibold">Run 2: {run2.run_id}</h3>
                            <span className={`px-2 py-1 rounded text-xs font-bold ${run2.backend === 'gpu' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'
                                }`}>
                                {run2.backend.toUpperCase()}
                            </span>
                        </div>
                        <div className="space-y-3">
                            <div>
                                <p className="text-sm text-muted-foreground">Latency</p>
                                <p className="text-2xl font-mono">
                                    {Math.round(run2.latency_ms)} ms{' '}
                                    <DiffBadge val1={run1.latency_ms} val2={run2.latency_ms} />
                                </p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Energy</p>
                                <p className="text-2xl font-mono text-yellow-400">
                                    {Math.round(run2.energy_joules)} J{' '}
                                    <DiffBadge val1={run1.energy_joules} val2={run2.energy_joules} />
                                </p>
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">EDP</p>
                                <p className="text-2xl font-mono text-blue-400">
                                    {(run2.latency_ms * run2.energy_joules / 1000).toFixed(1)} k{' '}
                                    <DiffBadge
                                        val1={run1.latency_ms * run1.energy_joules}
                                        val2={run2.latency_ms * run2.energy_joules}
                                    />
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="mt-6 p-4 bg-muted/50 rounded-lg">
                    <h4 className="font-semibold mb-2">Summary</h4>
                    <p className="text-sm text-muted-foreground">
                        {run2.latency_ms < run1.latency_ms ? (
                            <>Run 2 is <strong>{Math.abs(calculateDiff(run1.latency_ms, run2.latency_ms)).toFixed(1)}% faster</strong></>
                        ) : (
                            <>Run 1 is <strong>{Math.abs(calculateDiff(run2.latency_ms, run1.latency_ms)).toFixed(1)}% faster</strong></>
                        )}
                        {' and '}
                        {run2.energy_joules < run1.energy_joules ? (
                            <>Run 2 uses <strong>{Math.abs(calculateDiff(run1.energy_joules, run2.energy_joules)).toFixed(1)}% less energy</strong>.</>
                        ) : (
                            <>Run 1 uses <strong>{Math.abs(calculateDiff(run2.energy_joules, run1.energy_joules)).toFixed(1)}% less energy</strong>.</>
                        )}
                    </p>
                </div>
            </div>
        </div>
    );
}
