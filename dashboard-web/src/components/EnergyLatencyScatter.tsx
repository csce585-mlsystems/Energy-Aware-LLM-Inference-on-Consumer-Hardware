import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

export function EnergyLatencyScatter({ runs }: { runs: any[] }) {
    const data = runs.map(run => ({
        latency: run.latency_ms,
        energy: run.energy_joules,
        backend: run.backend,
        id: run.run_id
    }));

    return (
        <div className="w-full h-[400px] bg-card border rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-4 text-foreground">Energy vs Latency Trade-off</h3>
            <ResponsiveContainer width="100%" height="100%">
                <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                        type="number"
                        dataKey="latency"
                        name="Latency (ms)"
                        stroke="#94a3b8"
                        label={{ value: 'Latency (ms)', position: 'insideBottom', offset: -10, fill: '#94a3b8' }}
                    />
                    <YAxis
                        type="number"
                        dataKey="energy"
                        name="Energy (J)"
                        stroke="#94a3b8"
                        label={{ value: 'Energy (J)', angle: -90, position: 'insideLeft', fill: '#94a3b8' }}
                    />
                    <Tooltip
                        contentStyle={{ backgroundColor: '#334155', border: '1px solid #475569', borderRadius: '6px', color: '#f1f5f9' }}
                        cursor={{ strokeDasharray: '3 3' }}
                        labelStyle={{ color: '#e2e8f0' }}
                    />
                    <Scatter data={data} fill="#8884d8">
                        {data.map((entry, index) => (
                            <Cell
                                key={`cell-${index}`}
                                fill={entry.backend === 'gpu' ? '#10b981' : '#f97316'}
                            />
                        ))}
                    </Scatter>
                </ScatterChart>
            </ResponsiveContainer>
            <div className="flex gap-4 justify-center mt-4">
                <div className="flex items-center gap-2">
                    <div className="w-4 h-4 bg-green-500 rounded-full"></div>
                    <span className="text-sm text-muted-foreground">GPU</span>
                </div>
                <div className="flex items-center gap-2">
                    <div className="w-4 h-4 bg-orange-500 rounded-full"></div>
                    <span className="text-sm text-muted-foreground">CPU</span>
                </div>
            </div>
        </div>
    );
}
