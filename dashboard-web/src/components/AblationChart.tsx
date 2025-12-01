import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export function AblationChart({ runs, type }: { runs: any[], type: 'threads' | 'layers' | 'batch' }) {
    // Group data by the ablation parameter
    const groupedData: Record<string, { latency: number[], energy: number[] }> = {};

    runs.forEach(run => {
        let key = '';
        if (type === 'threads' && run.run_id.includes('cpu-t')) {
            key = run.run_id.split('-')[1]; // e.g., "t4" -> "t4"
        } else if (type === 'layers' && run.run_id.includes('gpu-l')) {
            key = run.run_id.split('-')[1]; // e.g., "l11" -> "l11"
        } else if (type === 'batch' && run.run_id.includes('gpu-b')) {
            key = run.run_id.split('-')[1]; // e.g., "b512" -> "b512"
        }

        if (key) {
            if (!groupedData[key]) {
                groupedData[key] = { latency: [], energy: [] };
            }
            groupedData[key].latency.push(run.latency_ms);
            groupedData[key].energy.push(run.energy_joules);
        }
    });

    // Calculate averages
    const chartData = Object.keys(groupedData).map(key => ({
        name: key.toUpperCase(),
        latency: Math.round(groupedData[key].latency.reduce((a, b) => a + b, 0) / groupedData[key].latency.length),
        energy: Math.round(groupedData[key].energy.reduce((a, b) => a + b, 0) / groupedData[key].energy.length)
    }));

    const titles = {
        threads: 'CPU Thread Scaling',
        layers: 'GPU Layer Offloading',
        batch: 'Batch Size Comparison'
    };

    return (
        <div className="w-full h-[350px] bg-card border rounded-lg p-4">
            <h3 className="text-lg font-semibold mb-4 text-foreground">{titles[type]}</h3>
            <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis dataKey="name" stroke="#94a3b8" />
                    <YAxis yAxisId="left" orientation="left" stroke="#94a3b8" />
                    <YAxis yAxisId="right" orientation="right" stroke="#94a3b8" />
                    <Tooltip
                        contentStyle={{ backgroundColor: '#334155', border: '1px solid #475569', borderRadius: '6px', color: '#f1f5f9' }}
                        labelStyle={{ color: '#e2e8f0' }}
                    />
                    <Legend />
                    <Bar yAxisId="left" dataKey="latency" fill="#3b82f6" name="Latency (ms)" />
                    <Bar yAxisId="right" dataKey="energy" fill="#f59e0b" name="Energy (J)" />
                </BarChart>
            </ResponsiveContainer>
        </div>
    );
}
