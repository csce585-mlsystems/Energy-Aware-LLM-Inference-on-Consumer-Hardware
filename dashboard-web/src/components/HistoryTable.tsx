import { Trophy } from 'lucide-react';

export function HistoryTable({ runs }: { runs: any[] }) {
    return (
        <div className="w-full bg-card border rounded-lg overflow-hidden">
            <div className="p-4 border-b bg-muted/50">
                <h3 className="text-lg font-semibold flex items-center gap-2">
                    <Trophy className="w-5 h-5 text-yellow-500" />
                    Experiment History
                </h3>
            </div>
            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                    <thead className="text-xs uppercase bg-muted text-muted-foreground">
                        <tr>
                            <th className="px-6 py-3">Run ID</th>
                            <th className="px-6 py-3">Backend</th>
                            <th className="px-6 py-3">Latency (ms)</th>
                            <th className="px-6 py-3">Energy (J)</th>
                            <th className="px-6 py-3">EDP Score</th>
                        </tr>
                    </thead>
                    <tbody>
                        {runs.map((run, idx) => {
                            const edp = (run.latency_ms * run.energy_joules).toFixed(0);
                            return (
                                <tr key={idx} className="border-b border-border hover:bg-muted/50 transition-colors">
                                    <td className="px-6 py-4 font-medium">{run.run_id}</td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 rounded text-xs font-bold ${run.backend === 'gpu' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'
                                            }`}>
                                            {run.backend.toUpperCase()}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">{Math.round(run.latency_ms)}</td>
                                    <td className="px-6 py-4">{Math.round(run.energy_joules)}</td>
                                    <td className="px-6 py-4 font-mono text-blue-400">{edp}</td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
