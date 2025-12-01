import { Trophy } from 'lucide-react';
import { InfoTooltip } from './InfoTooltip';

interface HistoryTableProps {
    runs: any[];
    selectedRuns?: string[];
    onToggleSelection?: (runId: string) => void;
}

export function HistoryTable({ runs, selectedRuns = [], onToggleSelection }: HistoryTableProps) {
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
                            {onToggleSelection && <th className="px-6 py-3 w-12">Select</th>}
                            <th className="px-6 py-3">Run ID</th>
                            <th className="px-6 py-3">Backend</th>
                            <th className="px-6 py-3">
                                <span className="flex items-center">
                                    Latency (ms)
                                    <InfoTooltip text="Time taken to generate the response. Lower is better." />
                                </span>
                            </th>
                            <th className="px-6 py-3">
                                <span className="flex items-center">
                                    Energy (J)
                                    <InfoTooltip text="Total energy consumed during inference. Lower means more power-efficient." />
                                </span>
                            </th>
                            <th className="px-6 py-3">
                                <span className="flex items-center">
                                    EDP Score
                                    <InfoTooltip text="Energy-Delay Product: Latency × Energy. Balances speed and efficiency. Lower is better." />
                                </span>
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        {runs.map((run, idx) => {
                            const edp = (run.latency_ms * run.energy_joules).toFixed(0);
                            const isSelected = selectedRuns.includes(run.run_id);
                            return (
                                <tr key={idx} className={`border-b border-border hover:bg-muted/50 transition-colors ${isSelected ? 'bg-primary/10' : ''}`}>
                                    {onToggleSelection && (
                                        <td className="px-6 py-4">
                                            <input
                                                type="checkbox"
                                                checked={isSelected}
                                                onChange={() => onToggleSelection(run.run_id)}
                                                disabled={!isSelected && selectedRuns.length >= 2}
                                                className="w-4 h-4 cursor-pointer"
                                            />
                                        </td>
                                    )}
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
